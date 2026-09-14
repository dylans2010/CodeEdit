import { Hono } from 'hono';

const app = new Hono();
app.get('/', (c) => c.json({ service: '{{PROJECT_NAME}}', runtime: 'universal' }));

export default app;
