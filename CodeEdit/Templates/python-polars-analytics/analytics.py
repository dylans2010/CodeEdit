import polars as pl

print("Running {{PROJECT_NAME}} Polars analytics query...")
df = pl.DataFrame({
    "category": ["A", "B", "A", "B", "C"],
    "revenue": [100, 200, 150, 250, 300]
})
summary = df.group_by("category").sum()
print(summary)
