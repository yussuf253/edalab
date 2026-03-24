import cors from 'cors';
import express from 'express';
import { env } from './config/env';
import apiRoutes from './routes';
import { errorHandler, notFoundHandler } from './middleware/error-handler';

const app = express();

app.use(
  cors({
    origin: env.CORS_ORIGIN === '*' ? true : env.CORS_ORIGIN,
    credentials: true,
  }),
);
app.use(express.json());

app.use('/api', apiRoutes);
app.use(notFoundHandler);
app.use(errorHandler);

app.listen(env.PORT, '0.0.0.0', () => {
  console.log(`EdaLab API running on http://0.0.0.0:${env.PORT}`);
});
