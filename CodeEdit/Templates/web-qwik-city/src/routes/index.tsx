import { component$, useSignal } from '@builder.io/qwik';

export default component$(() => {
  const count = useSignal(0);
  return (
    <main style={{ padding: "2rem", fontFamily: "sans-serif" }}>
      <h1>{{PROJECT_NAME}}</h1>
      <p>Resumable Qwik App</p>
      <button onClick$={() => count.value++}>Count: {count.value}</button>
    </main>
  );
});
