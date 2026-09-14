let count = 0;
const btn = document.getElementById("counter-btn");
btn.addEventListener("click", () => {
  count++;
  btn.textContent = `Clicks: ${count}`;
});
