import { Elysia } from 'elysia';

const app = new Elysia()
  .get('/', () => ({ project: '{{PROJECT_NAME}}', status: 'blazing fast' }))
  .listen(3000);

console.log(`🦊 Elysia is running at ${app.server?.hostname}:${app.server?.port}`);
