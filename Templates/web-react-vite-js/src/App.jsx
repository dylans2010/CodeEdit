import { useState } from 'react'

export default function App() {
  const [count, setCount] = useState(0)
  return (
    <main style={{ textAlign: 'center', padding: '3rem', fontFamily: 'sans-serif' }}>
      <h1>{{PROJECT_NAME}}</h1>
      <button onClick={() => setCount(c => c + 1)}>Clicks: {count}</button>
    </main>
  )
}
