"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const async_handler_1 = require("../utils/async-handler");
const module_settings_1 = require("../utils/module-settings");
const router = (0, express_1.Router)();
router.get('/', (0, async_handler_1.asyncHandler)(async (_req, res) => {
    try {
        const modules = await (0, module_settings_1.listManagedModules)();
        return res.json(modules);
    }
    catch {
        // Keep the app functional while the DB schema is being migrated.
        return res.json((0, module_settings_1.defaultManagedModules)());
    }
}));
exports.default = router;
