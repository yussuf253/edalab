"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const appointments_routes_1 = __importDefault(require("./appointments.routes"));
const auth_routes_1 = __importDefault(require("./auth.routes"));
const catalog_routes_1 = __importDefault(require("./catalog.routes"));
const modules_routes_1 = __importDefault(require("./modules.routes"));
const notifications_routes_1 = __importDefault(require("./notifications.routes"));
const orders_routes_1 = __importDefault(require("./orders.routes"));
const promotions_routes_1 = __importDefault(require("./promotions.routes"));
const users_routes_1 = __importDefault(require("./users.routes"));
const router = (0, express_1.Router)();
router.get('/health', (_req, res) => {
    res.json({
        status: 'ok',
        message: 'EdaLab API is running',
    });
});
router.use('/auth', auth_routes_1.default);
router.use('/catalog', catalog_routes_1.default);
router.use('/modules', modules_routes_1.default);
router.use('/users', users_routes_1.default);
router.use('/orders', orders_routes_1.default);
router.use('/appointments', appointments_routes_1.default);
router.use('/promotions', promotions_routes_1.default);
router.use('/notifications', notifications_routes_1.default);
exports.default = router;
