import pandas as pd

# Load the dataset
df = pd.read_csv("data/RAW_recipes.csv")

print("=" * 60)
print("Number of recipes:", len(df))
print("=" * 60)

print("\nColumns:")
print(df.columns.tolist())

print("\nFirst Recipe:")
print(df.iloc[0])

print("\nDataset Info:")
print(df.info())