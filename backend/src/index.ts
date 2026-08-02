import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { Bindings } from './types';

// Import Routers
import authApp from './routes/auth';
import usersApp from './routes/users';
import shopsApp from './routes/shops';
import customersApp from './routes/customers';
import productsApp from './routes/products';
import billsApp from './routes/bills';
import syncApp from './routes/sync';

const app = new Hono<{ Bindings: Bindings }>();

// Middleware
app.use('*', cors());

// Health Check
app.get('/api/health', (c) => c.json({ status: 'ok', message: 'RetailFlow Cloudflare Backend API is running!' }));
app.get('/', (c) => c.text('RetailFlow API Root'));

// Mount Routers
app.route('/api/auth', authApp);
app.route('/api/users', usersApp);
app.route('/api/shops', shopsApp);
app.route('/api/customers', customersApp);
app.route('/api/products', productsApp);
app.route('/api/bills', billsApp);
app.route('/api/sync', syncApp);

export default app;
