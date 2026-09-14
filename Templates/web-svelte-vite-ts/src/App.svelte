<script lang="ts">
  let count: number = 0;
  function increment() { count += 1; }
</script>

<main>
  <h1>{{PROJECT_NAME}}</h1>
  <button on:click={increment}>Count: {count}</button>
</main>

<style>
  main { text-align: center; padding: 3rem; font-family: sans-serif; }
  button { padding: 8px 16px; border-radius: 6px; cursor: pointer; }
</style>
