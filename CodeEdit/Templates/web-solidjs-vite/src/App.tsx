import { createSignal } from 'solid-js'

export default function App() {
  const [count, setCount] = createSignal(0)
  return (
    <main style={{ "text-align": "center", "padding": "3rem" }}>
      <h1>{{PROJECT_NAME}}</h1>
      <button onClick={() => setCount(c => c + 1)}>Clicks: {count()}</button>
    </main>
  )
}
