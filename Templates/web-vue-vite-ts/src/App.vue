<script setup lang="ts">
import { ref } from 'vue'

const count = ref(0)
</script>

<template>
  <main class="container">
    <h1>{{PROJECT_NAME}}</h1>
    <p>Vue 3 + Vite + TypeScript Starter</p>
    <button @click="count++">Count is {{ count }}</button>
  </main>
</template>

<style scoped>
.container {
  text-align: center;
  font-family: sans-serif;
  margin-top: 4rem;
}
button {
  padding: 0.5rem 1rem;
  border-radius: 6px;
  cursor: pointer;
}
</style>
