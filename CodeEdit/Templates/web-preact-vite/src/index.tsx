import { render } from 'preact';
import { useState } from 'preact/hooks';

export function App() {
  const [val, setVal] = useState(0);
  return (
    <div style={{ textAlign: "center", padding: "2rem", fontFamily: "sans-serif" }}>
      <h1>{{PROJECT_NAME}}</h1>
      <button onClick={() => setVal(v => v + 1)}>Preact Clicks: {val}</button>
    </div>
  );
}

render(<App />, document.getElementById('app')!);
