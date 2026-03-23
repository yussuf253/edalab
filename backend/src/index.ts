import express, { Request, Response } from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import crypto from 'crypto';
import { promisify } from 'util';
import prisma from './db';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 5050;
const scrypt = promisify(crypto.scrypt);
const userInclude = {
  addresses: {
    orderBy: [
      { isDefault: 'desc' },
      { updatedAt: 'desc' },
    ],
  },
};
const prismaWithAddresses = prisma as any;

type SafeAddress = {
  id: string;
  label: string;
  address: string;
  city: string | null;
  zipCode: string | null;
  latitude: number | null;
  longitude: number | null;
  isDefault: boolean;
};

type SafeUser = {
  id: string;
  email: string;
  name: string;
  phone: string | null;
  avatarUrl: string | null;
  address: string | null;
  createdAt: Date;
  updatedAt: Date;
  addresses: SafeAddress[];
};

async function hashPassword(password: string): Promise<string> {
  const salt = crypto.randomBytes(16).toString('hex');
  const derivedKey = (await scrypt(password, salt, 64)) as Buffer;
  return `${salt}:${derivedKey.toString('hex')}`;
}

async function verifyPassword(password: string, passwordHash: string): Promise<boolean> {
  const [salt, storedHash] = passwordHash.split(':');
  if (!salt || !storedHash) {
    return false;
  }

  const derivedKey = (await scrypt(password, salt, 64)) as Buffer;
  const storedBuffer = Buffer.from(storedHash, 'hex');

  if (storedBuffer.length != derivedKey.length) {
    return false;
  }

  return crypto.timingSafeEqual(storedBuffer, derivedKey);
}

function sanitizeUser(user: {
  id: string;
  email: string;
  name: string;
  phone: string | null;
  avatarUrl: string | null;
  address: string | null;
  createdAt: Date;
  updatedAt: Date;
  addresses?: Array<{
    id: string;
    label: string;
    address: string;
    city: string | null;
    zipCode: string | null;
    latitude: number | null;
    longitude: number | null;
    isDefault: boolean;
  }>;
}): SafeUser {
  return {
    id: user.id,
    email: user.email,
    name: user.name,
    phone: user.phone,
    avatarUrl: user.avatarUrl,
    address: user.address,
    createdAt: user.createdAt,
    updatedAt: user.updatedAt,
    addresses: (user.addresses ?? []).map((address) => ({
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

app.use(cors());
app.use(express.json());

app.get('/api/health', (req: Request, res: Response) => {
  res.json({ status: 'ok', message: 'EdaLab API is running' });
});

app.get('/api/modules', (req: Request, res: Response) => {
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

app.get('/api/users', async (req: Request, res: Response) => {
  try {
    const users = await prisma.user.findMany({
      include: userInclude as any,
    });
    res.json(users.map(sanitizeUser));
  } catch (error) {
    res.status(500).json({ error: 'Database connection error' });
  }
});

app.post('/api/users', async (req: Request, res: Response) => {
  try {
    const { email, name, phone, password } = req.body;

    if (!email || !name || !password) {
      return res.status(400).json({ error: 'Name, email, and password are required.' });
    }

    const existingUser = await prisma.user.findUnique({ where: { email } });
    if (existingUser) {
      return res.status(409).json({ error: 'An account with this email already exists.' });
    }

    const passwordHash = await hashPassword(password);
    const user = await prisma.user.create({
      data: { email, name, phone, passwordHash },
      include: userInclude as any,
    });
    res.status(201).json(sanitizeUser(user));
  } catch (error) {
    res.status(400).json({ error: 'Could not create user' });
  }
});

app.post('/api/users/login', async (req: Request, res: Response) => {
  try {
    const { email, password } = req.body;
    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password are required.' });
    }

    const user = await prisma.user.findUnique({
      where: { email },
      include: userInclude as any,
    });
    if (!user) {
      return res.status(401).json({ error: 'Invalid email or password.' });
    }

    const isValidPassword = await verifyPassword(password, user.passwordHash);
    if (!isValidPassword) {
      return res.status(401).json({ error: 'Invalid email or password.' });
    }

    res.json(sanitizeUser(user));
  } catch (error) {
    res.status(500).json({ error: 'Server error during login' });
  }
});

app.get('/api/users/:id', async (req: Request, res: Response) => {
  try {
    const userId = Array.isArray(req.params.id) ? req.params.id[0] : req.params.id;
    const user = await prisma.user.findUnique({
      where: { id: userId },
      include: userInclude as any,
    });

    if (!user) {
      return res.status(404).json({ error: 'User not found.' });
    }

    res.json(sanitizeUser(user));
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch user profile.' });
  }
});

app.patch('/api/users/:id', async (req: Request, res: Response) => {
  try {
    const userId = Array.isArray(req.params.id) ? req.params.id[0] : req.params.id;
    const { email, name, phone, avatarUrl } = req.body;

    if (!email || !name) {
      return res.status(400).json({ error: 'Name and email are required.' });
    }

    const existingUser = await prisma.user.findUnique({ where: { id: userId } });
    if (!existingUser) {
      return res.status(404).json({ error: 'User not found.' });
    }

    const userWithEmail = await prisma.user.findUnique({ where: { email } });
    if (userWithEmail && userWithEmail.id !== userId) {
      return res.status(409).json({ error: 'That email is already being used by another account.' });
    }

    const updatedUser = await prisma.user.update({
      where: { id: userId },
      data: {
        email,
        name,
        phone: phone || null,
        avatarUrl: avatarUrl || null,
      },
      include: userInclude as any,
    });

    res.json(sanitizeUser(updatedUser));
  } catch (error) {
    res.status(500).json({ error: 'Failed to update user profile.' });
  }
});

app.post('/api/users/:id/addresses', async (req: Request, res: Response) => {
  try {
    const userId = Array.isArray(req.params.id) ? req.params.id[0] : req.params.id;
    const { label, address, city, zipCode, latitude, longitude, isDefault } = req.body;

    if (!label || !address) {
      return res.status(400).json({ error: 'Label and address are required.' });
    }

    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (!user) {
      return res.status(404).json({ error: 'User not found.' });
    }

    await prisma.$transaction(async (tx) => {
      const txWithAddresses = tx as any;
      const shouldBeDefault = Boolean(isDefault) ||
          (await txWithAddresses.address.count({ where: { userId } })) === 0;

      if (shouldBeDefault) {
        await txWithAddresses.address.updateMany({
          where: { userId, isDefault: true },
          data: { isDefault: false },
        });
      }

      await txWithAddresses.address.create({
        data: {
          userId,
          label,
          address,
          city: city || null,
          zipCode: zipCode || null,
          latitude: latitude ?? null,
          longitude: longitude ?? null,
          isDefault: shouldBeDefault,
        },
      });
    });

    const updatedUser = await prisma.user.findUnique({
      where: { id: userId },
      include: userInclude as any,
    });

    res.status(201).json(sanitizeUser(updatedUser!));
  } catch (error) {
    res.status(500).json({ error: 'Failed to add address.' });
  }
});

app.patch('/api/users/:id/addresses/:addressId', async (req: Request, res: Response) => {
  try {
    const userId = Array.isArray(req.params.id) ? req.params.id[0] : req.params.id;
    const addressId = Array.isArray(req.params.addressId) ? req.params.addressId[0] : req.params.addressId;
    const { label, address, city, zipCode, latitude, longitude, isDefault } = req.body;

    const existingAddress = await prismaWithAddresses.address.findFirst({
      where: { id: addressId, userId },
    });

    if (!existingAddress) {
      return res.status(404).json({ error: 'Address not found.' });
    }

    await prisma.$transaction(async (tx) => {
      const txWithAddresses = tx as any;
      if (Boolean(isDefault)) {
        await txWithAddresses.address.updateMany({
          where: { userId, isDefault: true },
          data: { isDefault: false },
        });
      }

      await txWithAddresses.address.update({
        where: { id: addressId },
        data: {
          label: label ?? existingAddress.label,
          address: address ?? existingAddress.address,
          city: city === '' ? null : city ?? existingAddress.city,
          zipCode: zipCode === '' ? null : zipCode ?? existingAddress.zipCode,
          latitude: latitude ?? existingAddress.latitude,
          longitude: longitude ?? existingAddress.longitude,
          isDefault: Boolean(isDefault) ? true : existingAddress.isDefault,
        },
      });
    });

    const updatedUser = await prisma.user.findUnique({
      where: { id: userId },
      include: userInclude as any,
    });

    res.json(sanitizeUser(updatedUser!));
  } catch (error) {
    res.status(500).json({ error: 'Failed to update address.' });
  }
});

app.patch('/api/users/:id/addresses/:addressId/default', async (req: Request, res: Response) => {
  try {
    const userId = Array.isArray(req.params.id) ? req.params.id[0] : req.params.id;
    const addressId = Array.isArray(req.params.addressId) ? req.params.addressId[0] : req.params.addressId;

    const existingAddress = await prismaWithAddresses.address.findFirst({
      where: { id: addressId, userId },
    });

    if (!existingAddress) {
      return res.status(404).json({ error: 'Address not found.' });
    }

    await prisma.$transaction(async (tx) => {
      const txWithAddresses = tx as any;
      await txWithAddresses.address.updateMany({
        where: { userId, isDefault: true },
        data: { isDefault: false },
      });

      await txWithAddresses.address.update({
        where: { id: addressId },
        data: { isDefault: true },
      });
    });

    const updatedUser = await prisma.user.findUnique({
      where: { id: userId },
      include: userInclude as any,
    });

    res.json(sanitizeUser(updatedUser!));
  } catch (error) {
    res.status(500).json({ error: 'Failed to set default address.' });
  }
});

app.delete('/api/users/:id/addresses/:addressId', async (req: Request, res: Response) => {
  try {
    const userId = Array.isArray(req.params.id) ? req.params.id[0] : req.params.id;
    const addressId = Array.isArray(req.params.addressId) ? req.params.addressId[0] : req.params.addressId;

    const existingAddress = await prismaWithAddresses.address.findFirst({
      where: { id: addressId, userId },
    });

    if (!existingAddress) {
      return res.status(404).json({ error: 'Address not found.' });
    }

    await prismaWithAddresses.address.delete({
      where: { id: addressId },
    });

    if (existingAddress.isDefault) {
      const replacementAddress = await prismaWithAddresses.address.findFirst({
        where: { userId },
        orderBy: { updatedAt: 'desc' },
      });

      if (replacementAddress) {
        await prismaWithAddresses.address.update({
          where: { id: replacementAddress.id },
          data: { isDefault: true },
        });
      }
    }

    const updatedUser = await prisma.user.findUnique({
      where: { id: userId },
      include: userInclude as any,
    });

    res.json(sanitizeUser(updatedUser!));
  } catch (error) {
    res.status(500).json({ error: 'Failed to delete address.' });
  }
});

app.get('/api/orders/:userId', async (req: Request, res: Response) => {
  try {
    const userId = Array.isArray(req.params.userId) ? req.params.userId[0] : req.params.userId;
    const orders = await prisma.order.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });
    res.json(orders);
  } catch (error) {
    res.status(500).json({ error: 'Database connection error' });
  }
});

app.post('/api/orders', async (req: Request, res: Response) => {
  try {
    const { userId, moduleType, subtotal, tax, deliveryFee, total, items } = req.body;
    const order = await prisma.order.create({
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
  } catch (error) {
    console.error('Order Creation Error:', error);
    res.status(500).json({ error: 'Failed to create order' });
  }
});

app.get('/api/appointments/:userId', async (req: Request, res: Response) => {
  try {
    const userId = Array.isArray(req.params.userId) ? req.params.userId[0] : req.params.userId;
    const appointments = await prisma.appointment.findMany({
      where: { userId },
      orderBy: { date: 'asc' },
    });
    res.json(appointments);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch appointments' });
  }
});

app.post('/api/appointments', async (req: Request, res: Response) => {
  try {
    const { userId, doctorId, date, timeSlot, type, notes } = req.body;
    const appointment = await prisma.appointment.create({
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
  } catch (error) {
    console.error('Appointment Error:', error);
    res.status(500).json({ error: 'Failed to book appointment' });
  }
});

app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});
