import os
import pandas as pd
import numpy as np
# from tabulate import tabulate
user = os.getlogin()
basefolder = 'C:/Users/'+user+'/A&D Mortgage/Docs - Servicing/DMI/REPORTS/'
cwdteams = os.path.abspath(basefolder) 
root_folder = os.listdir(cwdteams)

columnsCheck = ['InvestorCode','CategoryCode','InvestorLoanNumber','LoanNumber','ShortName','AnnualInterestRate','ServiceFeeRate','DueDate','NextPaymentNumber','IntPaidTo','PrincipalBalance','PAndIConstant','PAndIConstantFlag','EscrowBalance','EscrowAdvanceBalance','SuspenseBalance','DeferredInterestBalance','RestrictedEscrowBalance','ReplacementReservesBalance','HudBalance','ARMIndicator','AsOfDate']

mistakes_dupl_csv = []
mistakes_columns = []
missed_file = []
files_written = []
file_total = 0

df = pd.DataFrame()
for year_folder in root_folder:
    if year_folder in ['REPORTS 2023']:
        print (year_folder)
        year_destination = os.listdir(basefolder + year_folder)   
        for month_folder in year_destination:
            if '.' not in month_folder and '07-2023' in month_folder:
                #print (month_folder)
                month_destination = os.listdir(basefolder + year_folder + '/' + month_folder)
                counter = 0
                for files in month_destination:
                    if 'P139' in files and '.csv' in files and '_E1--' in files:
                        #print(month_folder + '\n' + files)
                        csvpath = basefolder + year_folder + '/'+ month_folder + '/' + files
                        print(csvpath)
                        counter= counter+1
                        file_total = file_total+1
                        if counter < 2:
                            data = pd.read_csv(csvpath)
                            data["AsOfDate"] = files[14:24]
                            if list(data.columns) == columnsCheck:
                                df = pd.concat([df, data], ignore_index=True)
                                files_written.append(files[14:24])
                            else: 
                                mistakes_columns.append(files[14:24])
                        else:
                            mistakes_dupl_csv.append(csvpath)

print('------------------------------------------')
if len(files_written) == file_total:
    print(f'All good. Detected with {len(df)} rows')
    print('------------------------------------------')
else:
    if len(mistakes_dupl_csv) >0:
        print('Duplicated csvs path: '+ str(mistakes_dupl_csv))
        print('------------------------------------------')
    if len(mistakes_columns) >0:
        print('Wrong Columns: '+ str(mistakes_columns))
        print('------------------------------------------')
np.unique(df['AsOfDate'])
