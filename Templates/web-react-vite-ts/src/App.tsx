import { useState } from 'react'

export default function App() {
  const [count, setCount] = useState(0)

  return (
    <div className="card">
      <h1>{{PROJECT_NAME}}</h1>
      <p>React + Vite + TypeScript starter</p>
      <button onClick={() => setCount((c) => c + 1)}>
        count is {count}
      </button>
    </div>
  )
}
