--select * from [INFORMATION_SCHEMA].[COLUMNS]
--where column_name like '%purchased%'

select 

	lm.loanid									[Loan #]
	, case when du.lastrequestdate like '%1800%'
	then null 
	else du.lastrequestdate end as				[Last DU Request Date]
	, case when lm.datepurchased like '%1800%'
	then null 
	else lm.datepurchased end as				[Date Purchased]

from du_information								du 

left join loan_main								lm 
on lm.loanrecordid=du.loanrecordid


USE [dm01]
GO

/****** Object:  View [dbo].[retail_borr_emails]    Script Date: 9/27/2023 6:51:32 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

Create view [dbo].[retail_borr_emails] 
as
With all_cte as
					(--***FROM INTEGRA***
					SELECT 
						   lm.loanid													[Loan #]
						 , sbc.channelalias												[Channel]
						 , pot.occupancytypealias										[Occupancy]
						 , lm.ltv														[LTV]
						 , cm.email														[Borrowers Email]
						 , sls.statusdescription										[Loan Status]
						 , row_number() over(partition by lm.loanid order by lm.issrowversion desc)  
																						[Duplicate Counter]

					FROM integra.dbo.loan_main lm

					LEFT JOIN integra.dbo.customer_group cg
						ON cg.customergroupid=lm.customergroupid
						AND cg.lenderdatabaseid=lm.lenderdatabaseid

					INNER JOIN integra.dbo.customer_main cm 
						ON cm.lenderdatabaseid=cg.lenderdatabaseid
						AND cm.customerrecordid=cg.customerrecordid

					LEFT JOIN integra.dbo.setups_businesschannels sbc
						ON sbc.channelid = lm.businesschannelid

					LEFT JOIN integra.dbo.product_occupancytype pot
						ON pot.occupancytypeid=lm.occupancytypeid

					LEFT JOIN integra.dbo.setups_loanstatus sls
						ON lm.statusid=sls.statusid

					WHERE sbc.channelalias='Retail'
						AND lm.loanid !='Not Assigned'
						AND lm.statusid NOT in (199, 171, 184, 213) --inactive loans (cancelled, denied and etc.)
						AND lm.loanid NOT in 
								(
								SELECT 
									
									(SUBSTRING(LoanId, (LEN(LoanId)-(LEN(LoanId)-4)), LEN(LoanId))) [loanid] 
								FROM finastra.dbo.Status 
								WHERE warning in ('SOLD', 'PFF', 'Foreclosure') 
								) --filtering out loans that don't belong to A&D, Foreclosure and PayedOff loans
						
						
						
											UNION ALL


					--***OC SERVICING LOANS***
					SELECT

						 oc1.Loan_ID							[Loan #]
						, Page_1003_Channel						[Channel]
						, Page_1003_Property_Will_Be__Occupancy	[Occupancy]
						, Page_1003_LTV							[LTV]
						, oc2.Page_1003_Borrower_Email			[Borrowers Email]
						, Page_1003_Loan_Status_Lender			[Loan Status]
						, row_number() over(partition by oc1.Loan_ID order by oc2.Page_1003_Borrower_Email)										
																[Duplicate Counter]
					From dm01.dbo.OC_1 oc1

					JOIN dm01.dbo.OC_2 oc2
						ON oc2.Loan_ID=oc1.Loan_ID

					JOIN	(--***ALL THE SERVICING LOANS ***
								SELECT 
									(SUBSTRING(LoanId, (LEN(LoanId)-(LEN(LoanId)-4)), LEN(LoanId))) [loanid] 
								FROM finastra.dbo.Status 
								WHERE PrimStat in (0,1,7,8) --currently servicing and preparing to be serviced statuses
								and warning not in ('SOLD', 'PFF', 'Foreclosure') --filtering out loans that don't belong to A&D, Foreclosure and PayedOff loans
								and LoanID not like '000000%'
								and LoanID not like '0008%'
								and LoanID not like '002%'
								and LoanID not like '9%' --filterring out files, we don't have borrower emails in
								) sl
						ON oc1.Loan_ID = sl.loanid

					WHERE Page_1003_Channel = 'Retail'
						AND Page_1003_Loan_Status_Lender not in ('UW - Cancelled', 'Cancelled', 'Denied')	
						) --the end of the cte
Select 

	  [Loan #]
	, [Channel]
	, [Occupancy]
	, [LTV]
	, [Borrowers Email]
	, row_number() over (partition by [Borrowers Email] order by [Borrowers Email])
	  [Duplicate Counter]

FROM all_cte

WHERE [Duplicate Counter]=1 
GO

