"use strict";
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = __importDefault(require("express"));
const cors_1 = __importDefault(require("cors"));
const dotenv_1 = __importDefault(require("dotenv"));
const crypto_1 = __importDefault(require("crypto"));
const util_1 = require("util");
const db_1 = __importDefault(require("./db"));
dotenv_1.default.config();
const app = (0, express_1.default)();
const PORT = process.env.PORT || 5050;
const scrypt = (0, util_1.promisify)(crypto_1.default.scrypt);
const userInclude = {
    addresses: {
        orderBy: [
            { isDefault: 'desc' },
            { updatedAt: 'desc' },
        ],
    },
};
const prismaWithAddresses = db_1.default;
function hashPassword(password) {
    return __awaiter(this, void 0, void 0, function* () {
        const salt = crypto_1.default.randomBytes(16).toString('hex');
        const derivedKey = (yield scrypt(password, salt, 64));
        return `${salt}:${derivedKey.toString('hex')}`;
    });
}
function verifyPassword(password, passwordHash) {
    return __awaiter(this, void 0, void 0, function* () {
        const [salt, storedHash] = passwordHash.split(':');
        if (!salt || !storedHash) {
            return false;
        }
        const derivedKey = (yield scrypt(password, salt, 64));
        const storedBuffer = Buffer.from(storedHash, 'hex');
        if (storedBuffer.length != derivedKey.length) {
            return false;
        }
        return crypto_1.default.timingSafeEqual(storedBuffer, derivedKey);
    });
}
function sanitizeUser(user) {
    var _a;
    return {
        id: user.id,
        email: user.email,
        name: user.name,
        phone: user.phone,
        avatarUrl: user.avatarUrl,
        address: user.address,
        createdAt: user.createdAt,
        updatedAt: user.updatedAt,
        addresses: ((_a = user.addresses) !== null && _a !== void 0 ? _a : []).map((address) => ({
            id: address.id,
            label: address.label,
            address: address.address,
            city: address.city,
            zipCode: address.zipCode,
            latitude: address.latitude,
            longitude: address.longitude,
            isDefault: address.isDefault,
        })),
    };
}
app.use((0, cors_1.default)());
app.use(express_1.default.json());
app.get('/api/health', (req, res) => {
    res.json({ status: 'ok', message: 'EdaLab API is running' });
});
app.get('/api/modules', (req, res) => {
    res.json([
        { id: 'shopping', name: 'Shopping', active: true },
        { id: 'doctor', name: 'Doctor', active: true },
        { id: 'hotel', name: 'Hotel', active: true },
        { id: 'ride', name: 'Ride', active: true },
        { id: 'pharmacy', name: 'Pharmacy', active: true },
        { id: 'grocery', name: 'Grocery', active: true },
        { id: 'food', name: 'Food', active: true },
        { id: 'laundry', name: 'Laundry', active: true },
    ]);
});
app.get('/api/users', (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        const users = yield db_1.default.user.findMany({
            include: userInclude,
        });
        res.json(users.map(sanitizeUser));
    }
    catch (error) {
        res.status(500).json({ error: 'Database connection error' });
    }
}));
app.post('/api/users', (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        const { email, name, phone, password } = req.body;
        if (!email || !name || !password) {
            return res.status(400).json({ error: 'Name, email, and password are required.' });
        }
        const existingUser = yield db_1.default.user.findUnique({ where: { email } });
        if (existingUser) {
            return res.status(409).json({ error: 'An account with this email already exists.' });
        }
        const passwordHash = yield hashPassword(password);
        const user = yield db_1.default.user.create({
            data: { email, name, phone, passwordHash },
            include: userInclude,
        });
        res.status(201).json(sanitizeUser(user));
    }
    catch (error) {
        res.status(400).json({ error: 'Could not create user' });
    }
}));
app.post('/api/users/login', (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        const { email, password } = req.body;
        if (!email || !password) {
            return res.status(400).json({ error: 'Email and password are required.' });
        }
        const user = yield db_1.default.user.findUnique({
            where: { email },
            include: userInclude,
        });
        if (!user) {
            return res.status(401).json({ error: 'Invalid email or password.' });
        }
        const isValidPassword = yield verifyPassword(password, user.passwordHash);
        if (!isValidPassword) {
            return res.status(401).json({ error: 'Invalid email or password.' });
        }
        res.json(sanitizeUser(user));
    }
    catch (error) {
        res.status(500).json({ error: 'Server error during login' });
    }
}));
app.get('/api/users/:id', (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        const userId = Array.isArray(req.params.id) ? req.params.id[0] : req.params.id;
        const user = yield db_1.default.user.findUnique({
            where: { id: userId },
            include: userInclude,
        });
        if (!user) {
            return res.status(404).json({ error: 'User not found.' });
        }
        res.json(sanitizeUser(user));
    }
    catch (error) {
        res.status(500).json({ error: 'Failed to fetch user profile.' });
    }
}));
app.patch('/api/users/:id', (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        const userId = Array.isArray(req.params.id) ? req.params.id[0] : req.params.id;
        const { email, name, phone, avatarUrl } = req.body;
        if (!email || !name) {
            return res.status(400).json({ error: 'Name and email are required.' });
        }
        const existingUser = yield db_1.default.user.findUnique({ where: { id: userId } });
        if (!existingUser) {
            return res.status(404).json({ error: 'User not found.' });
        }
        const userWithEmail = yield db_1.default.user.findUnique({ where: { email } });
        if (userWithEmail && userWithEmail.id !== userId) {
            return res.status(409).json({ error: 'That email is already being used by another account.' });
        }
        const updatedUser = yield db_1.default.user.update({
            where: { id: userId },
            data: {
                email,
                name,
                phone: phone || null,
                avatarUrl: avatarUrl || null,
            },
            include: userInclude,
        });
        res.json(sanitizeUser(updatedUser));
    }
    catch (error) {
        res.status(500).json({ error: 'Failed to update user profile.' });
    }
}));
app.post('/api/users/:id/addresses', (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        const userId = Array.isArray(req.params.id) ? req.params.id[0] : req.params.id;
        const { label, address, city, zipCode, latitude, longitude, isDefault } = req.body;
        if (!label || !address) {
            return res.status(400).json({ error: 'Label and address are required.' });
        }
        const user = yield db_1.default.user.findUnique({ where: { id: userId } });
        if (!user) {
            return res.status(404).json({ error: 'User not found.' });
        }
        yield db_1.default.$transaction((tx) => __awaiter(void 0, void 0, void 0, function* () {
            const txWithAddresses = tx;
            const shouldBeDefault = Boolean(isDefault) ||
                (yield txWithAddresses.address.count({ where: { userId } })) === 0;
            if (shouldBeDefault) {
                yield txWithAddresses.address.updateMany({
                    where: { userId, isDefault: true },
                    data: { isDefault: false },
                });
            }
            yield txWithAddresses.address.create({
                data: {
                    userId,
                    label,
                    address,
                    city: city || null,
                    zipCode: zipCode || null,
                    latitude: latitude !== null && latitude !== void 0 ? latitude : null,
                    longitude: longitude !== null && longitude !== void 0 ? longitude : null,
                    isDefault: shouldBeDefault,
                },
            });
        }));
        const updatedUser = yield db_1.default.user.findUnique({
            where: { id: userId },
            include: userInclude,
        });
        res.status(201).json(sanitizeUser(updatedUser));
    }
    catch (error) {
        res.status(500).json({ error: 'Failed to add address.' });
    }
}));
app.patch('/api/users/:id/addresses/:addressId', (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        const userId = Array.isArray(req.params.id) ? req.params.id[0] : req.params.id;
        const addressId = Array.isArray(req.params.addressId) ? req.params.addressId[0] : req.params.addressId;
        const { label, address, city, zipCode, latitude, longitude, isDefault } = req.body;
        const existingAddress = yield prismaWithAddresses.address.findFirst({
            where: { id: addressId, userId },
        });
        if (!existingAddress) {
            return res.status(404).json({ error: 'Address not found.' });
        }
        yield db_1.default.$transaction((tx) => __awaiter(void 0, void 0, void 0, function* () {
            const txWithAddresses = tx;
            if (Boolean(isDefault)) {
                yield txWithAddresses.address.updateMany({
                    where: { userId, isDefault: true },
                    data: { isDefault: false },
                });
            }
            yield txWithAddresses.address.update({
                where: { id: addressId },
                data: {
                    label: label !== null && label !== void 0 ? label : existingAddress.label,
                    address: address !== null && address !== void 0 ? address : existingAddress.address,
                    city: city === '' ? null : city !== null && city !== void 0 ? city : existingAddress.city,
                    zipCode: zipCode === '' ? null : zipCode !== null && zipCode !== void 0 ? zipCode : existingAddress.zipCode,
                    latitude: latitude !== null && latitude !== void 0 ? latitude : existingAddress.latitude,
                    longitude: longitude !== null && longitude !== void 0 ? longitude : existingAddress.longitude,
                    isDefault: Boolean(isDefault) ? true : existingAddress.isDefault,
                },
            });
        }));
        const updatedUser = yield db_1.default.user.findUnique({
            where: { id: userId },
            include: userInclude,
        });
        res.json(sanitizeUser(updatedUser));
    }
    catch (error) {
        res.status(500).json({ error: 'Failed to update address.' });
    }
}));
app.patch('/api/users/:id/addresses/:addressId/default', (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        const userId = Array.isArray(req.params.id) ? req.params.id[0] : req.params.id;
        const addressId = Array.isArray(req.params.addressId) ? req.params.addressId[0] : req.params.addressId;
        const existingAddress = yield prismaWithAddresses.address.findFirst({
            where: { id: addressId, userId },
        });
        if (!existingAddress) {
            return res.status(404).json({ error: 'Address not found.' });
        }
        yield db_1.default.$transaction((tx) => __awaiter(void 0, void 0, void 0, function* () {
            const txWithAddresses = tx;
            yield txWithAddresses.address.updateMany({
                where: { userId, isDefault: true },
                data: { isDefault: false },
            });
            yield txWithAddresses.address.update({
                where: { id: addressId },
                data: { isDefault: true },
            });
        }));
        const updatedUser = yield db_1.default.user.findUnique({
            where: { id: userId },
            include: userInclude,
        });
        res.json(sanitizeUser(updatedUser));
    }
    catch (error) {
        res.status(500).json({ error: 'Failed to set default address.' });
    }
}));
app.delete('/api/users/:id/addresses/:addressId', (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        const userId = Array.isArray(req.params.id) ? req.params.id[0] : req.params.id;
        const addressId = Array.isArray(req.params.addressId) ? req.params.addressId[0] : req.params.addressId;
        const existingAddress = yield prismaWithAddresses.address.findFirst({
            where: { id: addressId, userId },
        });
        if (!existingAddress) {
            return res.status(404).json({ error: 'Address not found.' });
        }
        yield prismaWithAddresses.address.delete({
            where: { id: addressId },
        });
        if (existingAddress.isDefault) {
            const replacementAddress = yield prismaWithAddresses.address.findFirst({
                where: { userId },
                orderBy: { updatedAt: 'desc' },
            });
            if (replacementAddress) {
                yield prismaWithAddresses.address.update({
                    where: { id: replacementAddress.id },
                    data: { isDefault: true },
                });
            }
        }
        const updatedUser = yield db_1.default.user.findUnique({
            where: { id: userId },
            include: userInclude,
        });
        res.json(sanitizeUser(updatedUser));
    }
    catch (error) {
        res.status(500).json({ error: 'Failed to delete address.' });
    }
}));
app.get('/api/orders/:userId', (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        const userId = Array.isArray(req.params.userId) ? req.params.userId[0] : req.params.userId;
        const orders = yield db_1.default.order.findMany({
            where: { userId },
            orderBy: { createdAt: 'desc' },
        });
        res.json(orders);
    }
    catch (error) {
        res.status(500).json({ error: 'Database connection error' });
    }
}));
app.post('/api/orders', (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        const { userId, moduleType, subtotal, tax, deliveryFee, total, items } = req.body;
        const order = yield db_1.default.order.create({
            data: {
                userId,
                moduleType,
                subtotal: parseFloat(subtotal),
                tax: parseFloat(tax),
                deliveryFee: parseFloat(deliveryFee || '0'),
                total: parseFloat(total),
                items,
            },
        });
        res.json(order);
    }
    catch (error) {
        console.error('Order Creation Error:', error);
        res.status(500).json({ error: 'Failed to create order' });
    }
}));
app.get('/api/appointments/:userId', (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        const userId = Array.isArray(req.params.userId) ? req.params.userId[0] : req.params.userId;
        const appointments = yield db_1.default.appointment.findMany({
            where: { userId },
            orderBy: { date: 'asc' },
        });
        res.json(appointments);
    }
    catch (error) {
        res.status(500).json({ error: 'Failed to fetch appointments' });
    }
}));
app.post('/api/appointments', (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        const { userId, doctorId, date, timeSlot, type, notes } = req.body;
        const appointment = yield db_1.default.appointment.create({
            data: {
                userId,
                doctorId,
                date: new Date(date),
                timeSlot,
                type,
                notes,
            },
        });
        res.json(appointment);
    }
    catch (error) {
        console.error('Appointment Error:', error);
        res.status(500).json({ error: 'Failed to book appointment' });
    }
}));
app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
});
