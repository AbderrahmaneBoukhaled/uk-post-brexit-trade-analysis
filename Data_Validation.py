import pandas as pd
from sqlalchemy import create_engine
import matplotlib.pyplot as plt
import seaborn as sns
import warnings
warnings.filterwarnings('ignore')

engine = create_engine("mysql+pymysql://root:0000@localhost:3306/richlist")

# Load all tables
df1 = pd.read_sql("SELECT * FROM table1_trade_by_country", con=engine)
df2 = pd.read_sql("SELECT * FROM table2_trade_by_product", con=engine)
df3 = pd.read_sql("SELECT * FROM dataset3_gbp_exchange_rates", con=engine)
df4 = pd.read_sql("SELECT * FROM dataset4_uk_economic_indicators", con=engine)
df5 = pd.read_sql("SELECT * FROM dataset5_uk_trade_agreements", con=engine)
df6 = pd.read_sql("SELECT * FROM dataset6_trading_partner_gdp", con=engine)
df7 = pd.read_sql("SELECT * FROM uk_macro_1950_2025", con=engine)
# STEP 1 — DATA VALIDATION
# table1_trade_by_country"
print("=" * 50)
print("TABLE 1 — Trade by Country")
print(f"Shape: {df1.shape}")
print(f"Columns: {df1.columns.tolist()}")
print(f"Years: {sorted(df1['Year'].unique())}")
print(f"Countries: {df1['Country'].nunique()} unique")
print(df1.isnull().sum())
print(df1.describe())
print()
# table2_trade_by_product"
print("TABLE 2 — Trade by Product")
print(f"Shape: {df2.shape}")
print(f"Columns: {df2.columns.tolist()}")
print(f"Years: {sorted(df2['Year'].unique())}")
print(f"Product_Category: {df2['Product_Category'].nunique()} unique")
print(f"Product_Category: {sorted(df2['Product_Category'].unique())}")
print(df2.isnull().sum())
print(df2.describe())

print("TABLE 3 — Exchange Rates")
print("=" * 50)
print(f"Shape: {df3.shape}")
print(f"Columns: {df3.columns.tolist()}")

print(df3.describe())
print()

print("TABLE 4 — UK Economy")
print("=" * 50)
print(df4)
print()

print("TABLE 5 — Trade Agreements")
print("=" * 50)
print(df5)
print()

print("TABLE 6 — Partner GDP")
print("=" * 50)
print(f"Shape: {df6.shape}")
print(f"Countries: {df6['Country'].nunique()} unique")
print(df6.describe())

# kpi analysis
print("KPI 1 — Total Trade Pre vs Post Brexit")
print("=" * 50)

kpi1 = df1.groupby('Brexit_Period').agg(
    Total_Exports=('Exports_GBP_Millions', 'sum'),
    Total_Imports=('Imports_GBP_Millions', 'sum'),
    Years=('Year', 'nunique')
).round(2)

kpi1['Trade_Balance'] = kpi1['Total_Exports'] - kpi1['Total_Imports']
print(kpi1)

print("KPI 2 — EU vs Non-EU Split")
print("=" * 50)

kpi2 = df1.groupby(['EU_NonEU', 'Brexit_Period']).agg(
    Exports=('Exports_GBP_Millions', 'sum'),
    Imports=('Imports_GBP_Millions', 'sum')
).round(2)
kpi2['Balance'] = kpi2['Exports'] - kpi2['Imports']
print(kpi2)

print("\n" + "=" * 50)
print("KPI 3 — Top 10 Export Destinations")
print("=" * 50)

kpi3 = df1.groupby('Country').agg(
    Total_Exports=('Exports_GBP_Millions', 'sum'),
    Total_Imports=('Imports_GBP_Millions', 'sum')
).round(2)
kpi3['Trade_Balance'] = kpi3['Total_Exports'] - kpi3['Total_Imports']
kpi3 = kpi3.sort_values('Total_Exports', ascending=False).head(10)
print(kpi3)


print("\n" + "=" * 50)
print("KPI 4 — Year on Year Export Growth")
print("=" * 50)

kpi4 = df1.groupby('Year')['Exports_GBP_Millions'].sum().reset_index()
kpi4.columns = ['Year', 'Total_Exports']
kpi4['Prev_Year'] = kpi4['Total_Exports'].shift(1)
kpi4['Growth_Pct'] = ((kpi4['Total_Exports'] - kpi4['Prev_Year']) / kpi4['Prev_Year'] * 100).round(2)
print(kpi4)