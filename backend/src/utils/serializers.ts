import { Prisma } from '@prisma/client';

export function toNumber(value: Prisma.Decimal | number | null | undefined): number | null {
  if (value == null) {
    return null;
  }

  if (typeof value === 'number') {
    return value;
  }

  return Number(value.toString());
}

export function parseFullName(fullName: string) {
  const parts = fullName.trim().split(/\s+/).filter(Boolean);

  if (parts.length === 0) {
    return { firstName: 'User', lastName: '' };
  }

  return {
    firstName: parts[0],
    lastName: parts.slice(1).join(' '),
  };
}

export function sanitizeUser(user: {
  id: string;
  email: string;
  firstName: string;
  lastName: string;
  phone: string | null;
  avatarUrl: string | null;
  createdAt: Date;
  updatedAt: Date;
  addresses?: Array<{
    id: string;
    label: string;
    line1: string;
    line2: string | null;
    city: string | null;
    state: string | null;
    postalCode: string | null;
    latitude: number | null;
    longitude: number | null;
    isDefault: boolean;
  }>;
}) {
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
