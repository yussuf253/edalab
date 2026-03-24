"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getParam = getParam;
function getParam(value, label) {
    if (typeof value === 'string' && value.length > 0) {
        return value;
    }
    throw new Error(`${label} is required.`);
}
