from sqlalchemy import create_engine
from sqlalchemy.types import String

engine = create_engine("mssql+pyodbc://bi_report:kqFD45BGQ30Gc3DVXFei5PAXIe3k6pq3@bi-01.prod.admortgage.com/dm01?driver=ODBC Driver 17 for SQL Server")
df.to_sql('SERV_DMI_Monthly_Report', con=engine, index = False, if_exists = 'append')