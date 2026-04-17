import pandas as pd
from sqlalchemy import create_engine
import matplotlib.pyplot as plt
import seaborn as sns
import warnings
import numpy as np
from scipy import stats
from sklearn.linear_model import LinearRegression
from sklearn.preprocessing import StandardScaler
from statsmodels.tsa.arima.model import ARIMA
from statsmodels.tsa.stattools import adfuller

warnings.filterwarnings('ignore')

# =======================
# Step 0 — Connect to Database
# =======================
engine = create_engine("mysql+pymysql://root:0000@localhost:3306/richlist")

# Load tables
df1 = pd.read_sql("SELECT * FROM table1_trade_by_country", con=engine)
df2 = pd.read_sql("SELECT * FROM table2_trade_by_product", con=engine)
df3 = pd.read_sql("SELECT * FROM dataset3_gbp_exchange_rates", con=engine)
df4 = pd.read_sql("SELECT * FROM dataset4_uk_economic_indicators", con=engine)
df5 = pd.read_sql("SELECT * FROM dataset5_uk_trade_agreements", con=engine)
df6 = pd.read_sql("SELECT * FROM dataset6_trading_partner_gdp", con=engine)
df7 = pd.read_sql("SELECT * FROM uk_macro_1950_2025", con=engine)

# =======================
# Step 1 — Correlation Analysis
# =======================
print("\n" + "="*50)
print("CORRELATION ANALYSIS")
print("="*50)

# Rename columns to match your names exactly
econ_trade = df7.rename(columns={
    'GDP_GBP_Billions': 'GDP_GBP_Billions', 
    'Inflation_Pct': 'Inflation_Pct', 
    'Interest_Rate_Pct': 'Interest_Rate_Pct', 
    'exports_GBP_Billions': 'Exports_GBP_Billions', 
    'Imports GBP Billion': 'Imports_GBP_Billions'
})

# Convert numeric columns (replace comma with dot if needed)
cols_to_convert = ['GDP_GBP_Billions', 'Inflation_Pct', 'Interest_Rate_Pct', 'Exports_GBP_Billions', 'Imports_GBP_Billions']
for col in cols_to_convert:
    econ_trade[col] = econ_trade[col].astype(str).str.replace(',', '.').astype(float)

# Calculate correlations with exports
corr_gdp_exports = econ_trade['GDP_GBP_Billions'].corr(econ_trade['Exports_GBP_Billions'])
corr_inflation_exports = econ_trade['Inflation_Pct'].corr(econ_trade['Exports_GBP_Billions'])
corr_interest_exports = econ_trade['Interest_Rate_Pct'].corr(econ_trade['Exports_GBP_Billions'])

print(f"GDP vs Exports Correlation: {corr_gdp_exports:.4f}")
print(f"Inflation vs Exports Correlation: {corr_inflation_exports:.4f}")
print(f"Interest Rate vs Exports Correlation: {corr_interest_exports:.4f}")

# =======================
# Step 2 — Regression Analysis
# =======================
print("\n" + "="*50)
print("REGRESSION ANALYSIS — What Drives UK Exports?")
print("="*50)

# Features and target
X = econ_trade[['GDP_GBP_Billions', 'Inflation_Pct', 'Interest_Rate_Pct']].values
y = econ_trade['Exports_GBP_Billions'].values

# Standardize features
scaler = StandardScaler()
X_scaled = scaler.fit_transform(X)

# Fit linear regression
model = LinearRegression()
model.fit(X_scaled, y)

# Print results
print(f"R-squared: {model.score(X_scaled, y):.4f}")
print(f"GDP coefficient: {model.coef_[0]:.4f} (in billion GBP per 1 std dev change)")
print(f"Inflation coefficient: {model.coef_[1]:.4f} (in billion GBP per 1 std dev change)")
print(f"Interest Rate coefficient: {model.coef_[2]:.4f} (in billion GBP per 1 std dev change)")
print(f"Intercept: {model.intercept_:.4f} (baseline exports if all variables = 0)")

print("\nInterpretation:")
print(f"Every 1 std dev increase in GDP → exports change by {model.coef_[0]:.2f} billion GBP")
print(f"Every 1 std dev increase in inflation → exports change by {model.coef_[1]:.2f} billion GBP")
print(f"Every 1 std dev increase in interest rate → exports change by {model.coef_[2]:.2f} billion GBP")

# =======================
# Step 3 — ARIMA Forecasting (Fixed)
# =======================
print("\n" + "="*50)
print("ARIMA — UK Export Forecasting 2026-2028 (Post-2000 Data)")
print("="*50)

# Use only recent data (2000-2025) for ARIMA
df_recent = econ_trade[econ_trade['Year'] >= 2000].copy()
ts_recent = df_recent.set_index('Year')['Exports_GBP_Billions']

# Fit ARIMA(1,1,1)
model_recent = ARIMA(ts_recent, order=(1,1,1))
result_recent = model_recent.fit()

# Forecast 2026-2028
forecast_recent = result_recent.get_forecast(steps=3)
forecast_values = forecast_recent.predicted_mean
forecast_ci = forecast_recent.conf_int()

print("\nForecasts (in billion GBP):")
for i, year in enumerate([2026, 2027, 2028]):
    print(f"{year}: £{forecast_values.iloc[i]:,.2f}B")
    print(f"  95% CI: £{forecast_ci.iloc[i,0]:,.2f}B — £{forecast_ci.iloc[i,1]:,.2f}B")

# =======================
# Convert df1 Exports from Millions → Billions for plotting
# =======================
df1['Exports_GBP_Billions'] = df1['Exports_GBP_Millions'] / 1000  # NEW LINE

# ------------------------------
# Chart 1 — Trade Overview (2 subplots)
# ------------------------------
df_macro = econ_trade.copy()

fig, axes = plt.subplots(1, 2, figsize=(16, 6))
fig.suptitle('UK Trade Overview 1950-2025', fontsize=14, fontweight='bold')

axes[0].plot(df_macro['Year'], df_macro['Exports_GBP_Billions'],
             color='#2ecc71', linewidth=2)
axes[0].axvline(x=2020, color='red', linestyle='--', label='Brexit')
axes[0].set_title('UK Total Exports 1950-2025')
axes[0].set_xlabel('Year')
axes[0].set_ylabel('Exports GBP Billions')
axes[0].legend()

axes[1].scatter(df_macro['GDP_GBP_Billions'],
                df_macro['Exports_GBP_Billions'],
                color='#3498db', alpha=0.6)
axes[1].set_title(f'GDP vs Exports (r = {df_macro["GDP_GBP_Billions"].corr(df_macro["Exports_GBP_Billions"]):.4f})')
axes[1].set_xlabel('GDP GBP Billions')
axes[1].set_ylabel('Exports GBP Billions')

plt.tight_layout()
plt.savefig('chart1_trade_overview.png', dpi=150)
plt.show()

# ------------------------------
# Chart 2 — Brexit Impact (2016-2024)
# ------------------------------
fig, axes = plt.subplots(1, 2, figsize=(16, 6))
fig.suptitle('Brexit Impact Analysis 2016-2024', fontsize=14, fontweight='bold')

# EU vs Non-EU exports over time
eu_noneu = df1.groupby(['Year', 'EU_NonEU'])['Exports_GBP_Billions'].sum().unstack()
eu_noneu.plot(ax=axes[0], marker='o', linewidth=2)
axes[0].axvline(x=2020.5, color='red', linestyle='--', label='Brexit')
axes[0].set_title('EU vs Non-EU Exports')
axes[0].set_xlabel('Year')
axes[0].set_ylabel('Exports GBP Billions')

# YoY growth
kpi4 = df1.groupby('Year')['Exports_GBP_Billions'].sum().reset_index()
kpi4['Growth'] = kpi4['Exports_GBP_Billions'].pct_change() * 100
axes[1].bar(kpi4['Year'], kpi4['Growth'],
            color=['red' if x < 0 else 'green' for x in kpi4['Growth'].fillna(0)])
axes[1].set_title('Year on Year Export Growth %')
axes[1].set_xlabel('Year')
axes[1].set_ylabel('Growth %')
axes[1].axhline(y=0, color='black', linewidth=0.8)

plt.tight_layout()
plt.savefig('chart2_brexit_impact.png', dpi=150)
plt.show()

# ------------------------------
# Chart 3 — Correlation Heatmap
# ------------------------------
fig, ax = plt.subplots(figsize=(10, 8))

corr_data = df_macro[['Exports_GBP_Billions', 'GDP_GBP_Billions',
                      'Inflation_Pct', 'Interest_Rate_Pct']].corr()

sns.heatmap(corr_data,
            annot=True,
            fmt='.2f',
            cmap='RdYlGn',
            center=0,
            ax=ax,
            linewidths=0.5)

ax.set_title('Correlation Heatmap — UK Economic Variables (1950-2025)',
             fontsize=13, fontweight='bold')

plt.tight_layout()
plt.savefig('chart3_correlation_heatmap.png', dpi=150)
plt.show()

# ------------------------------
# Chart 4 — ARIMA Forecast 2026-2028
# ------------------------------
fig, ax = plt.subplots(figsize=(14, 7))

df_plot = df_macro[df_macro['Year'] >= 2016]
ax.plot(df_plot['Year'],
        df_plot['Exports_GBP_Billions'],
        marker='o', linewidth=2, color='#3498db',
        label='Historical Exports', markersize=5)

forecast_years = [2026, 2027, 2028]
forecast_vals = [381.52, 381.60, 381.62]
lower_ci = [272.92, 225.64, 189.15]
upper_ci = [490.11, 537.56, 574.09]

ax.plot(forecast_years, forecast_vals,
        marker='s', linewidth=2, color='#e74c3c',
        linestyle='--', label='Forecast', markersize=8)

ax.fill_between(forecast_years, lower_ci, upper_ci,
                alpha=0.2, color='red',
                label='95% Confidence Interval')

ax.axvline(x=2020.5, color='orange',
           linestyle='--', alpha=0.7, label='Brexit')

ax.set_title('UK Export Forecast 2026-2028 (ARIMA Model)',
             fontsize=14, fontweight='bold')
ax.set_xlabel('Year')
ax.set_ylabel('Exports (GBP Billions)')
ax.legend()
ax.grid(True, alpha=0.3)

plt.tight_layout()
plt.savefig('chart4_arima_forecast.png', dpi=150)
plt.show()