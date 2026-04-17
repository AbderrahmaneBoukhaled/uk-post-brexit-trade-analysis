
import pandas as pd
from sqlalchemy import create_engine

import pandas as pd
from sqlalchemy import create_engine

engine = create_engine("mysql+pymysql://root:0000@localhost:3306/richlist")

df1 = pd.read_sql("SELECT * FROM table1_trade_by_country", con=engine)
df2 = pd.read_sql("SELECT * FROM table2_trade_by_product", con=engine)
df3 = pd.read_sql("SELECT * FROM dataset3_gbp_exchange_rates", con=engine)
df4 = pd.read_sql("SELECT * FROM dataset4_uk_economic_indicators", con=engine)
df5 = pd.read_sql("SELECT * FROM dataset5_uk_trade_agreements", con=engine)
df6 = pd.read_sql("SELECT * FROM dataset6_trading_partner_gdp", con=engine)
df7 = pd.read_sql("SELECT * FROM uk_macro_1950_2025", con=engine)

print(df7.head())


# connect to MySQL database connection details
username = 'root'       # e.g., 'root'
password = '0000'       # your MySQL password
host = 'localhost'               # or your server IP
port = '3306'                    # default MySQL port
database = 'richlist'

engine = create_engine(f'mysql+pymysql://{username}:{password}@{host}:{port}/{database}')

df7.to_sql(name='richlist', con=engine, if_exists='replace', index=False)


print("Data exported to MySQL successfully!")

#make sure to CREATE DATABASE uk_retail_db; in sql then run 
#USE uk_retail_db; 
#SELECT * FROM retail_data LIMIT 10;
