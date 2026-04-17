"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.toNumber = toNumber;
exports.parseFullName = parseFullName;
exports.sanitizeUser = sanitizeUser;
function toNumber(value) {
    if (value == null) {
        return null;
    }
    if (typeof value === 'number') {
        return value;
    }
    return Number(value.toString());
}
function parseFullName(fullName) {
    const parts = fullName.trim().split(/\s+/).filter(Boolean);
    if (parts.length === 0) {
        return { firstName: 'User', lastName: '' };
    }
    return {
        firstName: parts[0],
        lastName: parts.slice(1).join(' '),
    };
}
function sanitizeUser(user) {
    return {
        id: user.id,
        email: user.email,
        name: [user.firstName, user.lastName].filter(Boolean).join(' ').trim(),
        phone: user.phone,
        avatarUrl: user.avatarUrl,
        address: user.addresses?.find((address) => address.isDefault)?.line1 ?? null,
        createdAt: user.createdAt,
        updatedAt: user.updatedAt,
        addresses: (user.addresses ?? []).map((address) => ({
            quartier: address.line2 ?? address.state,
            id: address.id,
            label: address.label,
            address: address.line1,
            city: address.city,
            zipCode: address.postalCode,
            latitude: address.latitude,
            longitude: address.longitude,
            isDefault: address.isDefault,
        })),
    };
}
