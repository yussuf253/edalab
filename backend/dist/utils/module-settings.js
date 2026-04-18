"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.defaultManagedModules = defaultManagedModules;
exports.moduleName = moduleName;
exports.isModuleEnabled = isModuleEnabled;
exports.listManagedModules = listManagedModules;
const client_1 = require("@prisma/client");
const db_1 = require("../db");
const MANAGED_MODULES = [
    { moduleType: client_1.ModuleType.SHOPPING, id: 'shopping', name: 'Shopping', sortOrder: 1 },
    { moduleType: client_1.ModuleType.FOOD, id: 'food', name: 'Food', sortOrder: 2 },
    { moduleType: client_1.ModuleType.DOCTOR, id: 'doctor', name: 'Doctor', sortOrder: 3 },
    { moduleType: client_1.ModuleType.HOTEL, id: 'hotel', name: 'Hotel', sortOrder: 4 },
    { moduleType: client_1.ModuleType.RIDE, id: 'ride', name: 'Ride', sortOrder: 5 },
    { moduleType: client_1.ModuleType.PHARMACY, id: 'pharmacy', name: 'Pharmacy', sortOrder: 6 },
    { moduleType: client_1.ModuleType.GROCERY, id: 'grocery', name: 'Grocery', sortOrder: 7 },
    { moduleType: client_1.ModuleType.HOME_SERVICES, id: 'home-services', name: 'Home Services', sortOrder: 8 },
    { moduleType: client_1.ModuleType.LAUNDRY, id: 'laundry', name: 'Laundry', sortOrder: 9 },
];
const moduleMap = new Map(MANAGED_MODULES.map((entry) => [entry.moduleType, entry]));
function defaultManagedModules() {
    return MANAGED_MODULES.map((definition) => ({
        id: definition.id,
        moduleType: definition.moduleType,
        name: definition.name,
        active: true,
        sortOrder: definition.sortOrder,
    }));
}
function canonicalModuleType(moduleType) {
    if (moduleType === client_1.ModuleType.HOUSE_HELP) {
        return client_1.ModuleType.HOME_SERVICES;
    }
    return moduleType;
}
function moduleName(moduleType) {
    const canonical = canonicalModuleType(moduleType);
    return moduleMap.get(canonical)?.name ?? canonical;
}
async function isModuleEnabled(moduleType) {
    const canonical = canonicalModuleType(moduleType);
    const config = await db_1.prisma.appModule.findUnique({
        where: { moduleType: canonical },
        select: { active: true },
    });
    return config?.active ?? true;
}
async function listManagedModules() {
    const records = await db_1.prisma.appModule.findMany({
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
