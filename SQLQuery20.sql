use dm01
select * from[dbo].[P185_Data_Q05_2023-09-29] 
where AsOfDate ='2023-09-29'

use dm01
select * from[dbo].[SERV_DMI_Monthly_Report_test]
where AsOfDate ='2023-09-29'


select * from [dbo].[SERV_DMI_Monthly_Report_test]

alter table [dbo].[SERV_DMI_Monthly_Report_test]


select * from [dbo].[SERV_DMI_PaidOff_Monthly_Report] where AsOfDate ='2023-09-29'

select * from SERV_main where AsOfDate ='2023-09-30'--21228 rows
select * from SERV_main where AsOfDate ='2023-08-31'--20632 rows
--_________________________________________________________________________Tables in dm01______________________________________________________

select * from [dbo].[SERV_DMI_P139_Monthly_Report]
where AsOfDate ='2023-09-29'--						2107 good

select * from [dbo].[SERV_DMI_Monthly_Report]
where AsOfDate ='2023-09-29'--						2101 good

select * from [dbo].[SERV_DMI_Q05_LossMit_Monthly_Report]
where AsOfDate ='2023-09-29'--						58 missing 2

select * from [dbo].[SERV_DMI_PaidOff_Monthly_Report]
where AsOfDate ='2023-09-29'--						6 good

select * from [dbo].[SERV_Finastra_Monthly_Report] --						no rows for 09-29

select * from [dbo].[SLS_OAKTREE_Standard_Daily]
where AsOfDate ='2023-09-29'--						no as of date col

select * from [dbo].[SERV_SLS_LastDateOfMonth]
where AsOfDate ='2023-09-30'--						no as of date
use dm01
select * from [dbo].SERV_Main
where AsOfDate ='2023-09-30'

--_____________________________________________________________________________________________________________________________________________

