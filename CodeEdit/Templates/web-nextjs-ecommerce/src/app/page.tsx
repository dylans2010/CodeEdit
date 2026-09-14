export default function StoreHome() {
  const products = [
    { id: 1, name: "Mechanical Keyboard", price: "$120" },
    { id: 2, name: "Ergonomic Mouse", price: "$85" },
    { id: 3, name: "4K Monitor", price: "$350" }
  ];
  return (
    <main style={{ padding: "2rem", fontFamily: "system-ui" }}>
      <h1>{{PROJECT_NAME}} Store</h1>
      <ul>
        {products.map(p => (
          <li key={p.id}>{p.name} - {p.price}</li>
        ))}
      </ul>
    </main>
  );
}
