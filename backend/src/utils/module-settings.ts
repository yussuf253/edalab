import { ModuleType } from '@prisma/client';
import { prisma } from '../db';

type ModuleDefinition = {
  readonly moduleType: ModuleType;
  readonly id: string;
  readonly name: string;
  readonly sortOrder: number;
};

const MANAGED_MODULES: readonly ModuleDefinition[] = [
  { moduleType: ModuleType.SHOPPING, id: 'shopping', name: 'Shopping', sortOrder: 1 },
  { moduleType: ModuleType.FOOD, id: 'food', name: 'Food', sortOrder: 2 },
  { moduleType: ModuleType.DOCTOR, id: 'doctor', name: 'Doctor', sortOrder: 3 },
  { moduleType: ModuleType.HOTEL, id: 'hotel', name: 'Hotel', sortOrder: 4 },
  { moduleType: ModuleType.RIDE, id: 'ride', name: 'Ride', sortOrder: 5 },
  { moduleType: ModuleType.PHARMACY, id: 'pharmacy', name: 'Pharmacy', sortOrder: 6 },
  { moduleType: ModuleType.GROCERY, id: 'grocery', name: 'Grocery', sortOrder: 7 },
  { moduleType: ModuleType.HOME_SERVICES, id: 'home-services', name: 'Home Services', sortOrder: 8 },
  { moduleType: ModuleType.LAUNDRY, id: 'laundry', name: 'Laundry', sortOrder: 9 },
];

const moduleMap = new Map<ModuleType, ModuleDefinition>(
  MANAGED_MODULES.map((entry) => [entry.moduleType, entry]),
);

export function defaultManagedModules() {
  return MANAGED_MODULES.map((definition) => ({
    id: definition.id,
    moduleType: definition.moduleType,
    name: definition.name,
    active: true,
    sortOrder: definition.sortOrder,
  }));
}

function canonicalModuleType(moduleType: ModuleType) {
  if (moduleType === ModuleType.HOUSE_HELP) {
    return ModuleType.HOME_SERVICES;
  }
  return moduleType;
}

export function moduleName(moduleType: ModuleType) {
  const canonical = canonicalModuleType(moduleType);
  return moduleMap.get(canonical)?.name ?? canonical;
}

export async function isModuleEnabled(moduleType: ModuleType) {
  const canonical = canonicalModuleType(moduleType);
  const config = await prisma.appModule.findUnique({
    where: { moduleType: canonical },
    select: { active: true },
  });
  return config?.active ?? true;
}

export async function listManagedModules() {
  const records = await prisma.appModule.findMany({
    where: {
      moduleType: {
        in: MANAGED_MODULES.map((entry) => entry.moduleType),
      },
    },
    orderBy: [{ sortOrder: 'asc' }, { name: 'asc' }],
  });

  const byType = new Map(records.map((record) => [record.moduleType, record]));
  return MANAGED_MODULES.map((definition) => {
    const record = byType.get(definition.moduleType);
    return {
      id: record?.slug ?? definition.id,
      moduleType: definition.moduleType,
      name: record?.name ?? definition.name,
      active: record?.active ?? true,
      sortOrder: record?.sortOrder ?? definition.sortOrder,
    };
  }).sort((left, right) => {
    if (left.sortOrder !== right.sortOrder) {
      return left.sortOrder - right.sortOrder;
    }
    return left.name.localeCompare(right.name);
  });
}
