"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const router = (0, express_1.Router)();
router.get('/', (_req, res) => {
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
exports.default = router;
