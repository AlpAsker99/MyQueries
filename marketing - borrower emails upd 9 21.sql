	select * 
	from INFORMATION_SCHEMA.columns 
	where column_name like '%ltv%' 
order by table_name 

--+======================================================== INTEGRA - LTV 70-80%, Primary, Retail =======================

SELECT 
	   lm.loanid													[Loan #]
	 , sbc.channelalias												[Channel]
	 , pot.occupancytypealias										[Occupancy]
	 , lm.ltv														[LTV]

FROM loan_main lm
Left JOIN setups_businesschannels sbc
	ON sbc.channelid = lm.businesschannelid
LEFT JOIN product_occupancytype pot
	ON pot.occupancytypeid=lm.occupancytypeid

WHERE sbc.channelalias='Retail'
	AND pot.occupancytypealias = 'OwnOcc'
	AND lm.ltv between 70 and 80


--+======================================================== INTEGRA - LTV 65-75%, Inv, Retail ============================


SELECT 
	   lm.loanid													[Loan #]
	 , sbc.channelalias												[Channel]
	 , pot.occupancytypealias										[Occupancy]
	 , lm.ltv														[LTV]

FROM loan_main lm
LEFT JOIN setups_businesschannels sbc
	ON sbc.channelid = lm.businesschannelid
LEFT JOIN product_occupancytype pot
	ON pot.occupancytypeid=lm.occupancytypeid

WHERE sbc.channelalias='Retail'
	AND pot.occupancytypealias in ('Investment', 'BPInv')
	AND lm.ltv between 65 and 75

--+======================================================== OC LTV 70-80%, Primary, Retail =======================

SELECT

	 Loan_ID								[Loan #]
	, Page_1003_LTV							[LTV]
	, Page_1003_Channel						[Channel]
	, Page_1003_Property_Will_Be__Occupancy	[Occupancy]

From dm01.dbo.OC_1 
WHERE cast(Page_1003_LTV as float) between 70.0 and 80.0
	AND Page_1003_Channel = 'Retail'
	AND Page_1003_Property_Will_Be__Occupancy ='Primary Residence'

--+======================================================== OC LTV 65-75%, Inv, Retail ===========================

SELECT

	 Loan_ID								[Loan #]
	, Page_1003_LTV							[LTV]
	, Page_1003_Channel						[Channel]
	, Page_1003_Property_Will_Be__Occupancy	[Occupancy]

From dm01.dbo.OC_1 
WHERE cast(Page_1003_LTV as float) between 65.0 and 75.0
	AND Page_1003_Channel = 'Retail'
	AND Page_1003_Property_Will_Be__Occupancy ='Investment'

--+======================================================== ALL SERVICING-ACTIVE LOANS BELONG TO A&D ===========================

SELECT 
	(SUBSTRING(LoanId, (LEN(LoanId)-(LEN(LoanId)-4)), LEN(LoanId))) [loanid] 
--LoanID
FROM finastra.dbo.Status 
WHERE PrimStat in (1,7,8) 
and warning not in ('SOLDBACK','SOLD','SLSBACK1', 'PFF')
and LoanID not like '000000%'
and LoanID not like '0008%'
and LoanID not like '002%'
and LoanID not like '9%'


--+======================================================== ALL LTV 65-75%, Inv, Retail ===========================

With all_cte as
					(--***ALL ACTIVE LOANS FROM INTEGRA***
					SELECT 
						   lm.loanid													[Loan #]
						 , sbc.channelalias												[Channel]
						 , pot.occupancytypealias										[Occupancy]
						 , lm.ltv														[LTV]
						 , cm.email														[Borrowers Email]
						 , row_number() over (partition by lm.loanid order by lm.issrowversion desc) 
																						[DuplicateCounter]
					FROM loan_main lm
					LEFT JOIN customer_group cg
						ON cg.customergroupid=lm.customergroupid
						AND cg.lenderdatabaseid=lm.lenderdatabaseid
					INNER JOIN customer_main cm 
						ON cm.lenderdatabaseid=cg.lenderdatabaseid
						AND cm.customerrecordid=cg.customerrecordid
					LEFT JOIN setups_businesschannels sbc
						ON sbc.channelid = lm.businesschannelid
					LEFT JOIN product_occupancytype pot
						ON pot.occupancytypeid=lm.occupancytypeid

					WHERE sbc.channelalias='Retail'
						AND pot.occupancytypealias in ('Investment', 'BPInv', 'OwnOcc')
						--AND cast(lm.ltv as float) between  65.0 and 75.0
						AND lm.loanid !='Not Assigned'
					

					UNION ALL

					--***OC LOANS***
					SELECT

						 oc1.Loan_ID							[Loan #]
						, Page_1003_Channel						[Channel]
						, Page_1003_Property_Will_Be__Occupancy	[Occupancy]
						, Page_1003_LTV							[LTV]
						, oc2.Page_1003_Borrower_Email			[Borowers Email]
						, null									[DuplicateCounter]						
																
					From dm01.dbo.OC_1 oc1
					INNER JOIN dm01.dbo.OC_2 oc2
						ON oc2.Loan_ID=oc1.Loan_ID
					WHERE Page_1003_Channel = 'Retail'
					
						--cast(Page_1003_LTV as float) between 65.0 and 75.0
						AND Page_1003_Property_Will_Be__Occupancy IN ('Investment', 'Primary Residence')
						)

Select 
	  [Loan #]
	, [Channel]
	, [Occupancy]
	, [LTV]
	, [Borowers Email]
FROM all_cte ac
INNER JOIN	(--***ALL THE SERVICING LOANS BELONGING TO A&D***
			SELECT 
				(SUBSTRING(LoanId, (LEN(LoanId)-(LEN(LoanId)-4)), LEN(LoanId))) [loanid] 
			--LoanID
			FROM finastra.dbo.Status 
			WHERE PrimStat in (1,7,8) 
			and warning not in ('SOLD', 'PFF')
			and LoanID not like '000000%'
			and LoanID not like '0008%'
			and LoanID not like '002%'
			and LoanID not like '9%'
			) sl
	ON cast(ac.[Loan #]as int)=cast(sl.loanid as int)
	WHERE [DuplicateCounter] is null or [DuplicateCounter]=1
ORDER BY [Loan #]

--+================================================== ALL LTV 70-80%, Primary, Retail ===========================
Create view retail_borr_emails 
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
						 , lm.issrowversion

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
						AND lm.loanid = '1008079'
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
	, [Loan Status]
	, [Channel]
	, [Occupancy]
	, [LTV]
	, [Borrowers Email]
	, row_number() over (partition by [Borrowers Email] order by [Borrowers Email])
	  [Duplicate Counter]

FROM all_cte

WHERE [Duplicate Counter]=1 

--COMMENT: THE ABOVE QUERY IS A QUERY USED FOR A [dbo].[retail_borrowers_emails] VIEW, THAT IS IN IT'S TURN USED IN THE [dbo].[retail_borrowers_email_finalver] VIEW.
--4 STEP "DUPLICATE COUNTER" (where [Duplicate Counter]=1) WAS USED TO ELIMINATE THE DUPLICATE EMAILS FROM OC AND INTEGRA. 
--THE [dbo].[retail_borrowers_email_finalver]  VIEW IS A FINAL TAB WITH ALL 'ACTIVE' LOANS

select * from [dbo].[retail_borrowers_emails_finalver]

select lm.loanid
from loan_main
where lm.loanid='1052418'

