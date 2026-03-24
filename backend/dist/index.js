"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const cors_1 = __importDefault(require("cors"));
const express_1 = __importDefault(require("express"));
const env_1 = require("./config/env");
const routes_1 = __importDefault(require("./routes"));
const error_handler_1 = require("./middleware/error-handler");
const app = (0, express_1.default)();
app.use((0, cors_1.default)({
    origin: env_1.env.CORS_ORIGIN === '*' ? true : env_1.env.CORS_ORIGIN,
    credentials: true,
}));
app.use(express_1.default.json());
app.use('/api', routes_1.default);
app.use(error_handler_1.notFoundHandler);
app.use(error_handler_1.errorHandler);
app.listen(env_1.env.PORT, '0.0.0.0', () => {
    console.log(`EdaLab API running on http://0.0.0.0:${env_1.env.PORT}`);
});
