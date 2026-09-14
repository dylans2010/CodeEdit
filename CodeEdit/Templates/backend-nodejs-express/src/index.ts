import express, { Request, Response } from 'express'
import cors from 'cors'

const app = express()
const port = process.env.PORT || 3000

app.use(cors())
app.use(express.json())

app.get('/', (req: Request, res: Response) => {
  res.json({ message: 'Welcome to {{PROJECT_NAME}} API!', status: 'online' })
})

app.get('/api/health', (req: Request, res: Response) => {
  res.json({ status: 'ok', uptime: process.uptime() })
})

app.listen(port, () => {
  console.log(`Server running at http://localhost:${port}`)
})
