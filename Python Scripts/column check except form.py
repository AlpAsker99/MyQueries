import os, glob as g, pandas as pd
a=str(os.getcwd())
print(a)
csv_list=(g.glob("*.csv"))
df=pd.read_csv(os.getcwd()+"\\"+csv_list[0])
