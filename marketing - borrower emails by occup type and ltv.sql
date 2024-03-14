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
					(--***FROM INTEGRA***
					SELECT 
						   lm.loanid													[Loan #]
						 , sbc.channelalias												[Channel]
						 , pot.occupancytypealias										[Occupancy]
						 , lm.ltv														[LTV]
						 , cm.email														[Borowers Email]
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
Create view retail_borrowers_emails2
as
With all_cte as
					(--***FROM INTEGRA***
					SELECT 
						   lm.loanid													[Loan #]
						 , sbc.channelalias												[Channel]
						 , pot.occupancytypealias										[Occupancy]
						 , lm.ltv														[LTV]
						 , cm.email														[Borowers Email]
						 , sls.statusdescription										[Loan Status]
						 , row_number() over(partition by lm.loanid order by cm.email)  [Duplicate Counter]

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
						--AND pot.occupancytypealias in ('OwnOcc')
						--AND cast(lm.ltv as float) between  70.0 and 80.0
						AND lm.loanid !='Not Assigned'
						AND lm.statusid NOT in (199, 171, 184, 213)
						
						

					UNION ALL

					--***OC LOANS***
					SELECT

						 oc1.Loan_ID							[Loan #]
						, Page_1003_Channel						[Channel]
						, Page_1003_Property_Will_Be__Occupancy	[Occupancy]
						, Page_1003_LTV							[LTV]
						, oc2.Page_1003_Borrower_Email			[Borowers Email]
						, Page_1003_Loan_Status_Lender			[Loan Status]
						, row_number() over(partition by oc1.Loan_ID order by oc2.Page_1003_Borrower_Email)										
																[Duplicate Counter]
					From dm01.dbo.OC_1 oc1
					INNER JOIN dm01.dbo.OC_2 oc2
						ON oc2.Loan_ID=oc1.Loan_ID
					WHERE --cast(Page_1003_LTV as float) between  70.0 and 80.0
						--AND 
						Page_1003_Channel = 'Retail'
						AND Page_1003_Loan_Status_Lender not in ('UW - Cancelled', 'Cancelled', 'Denied')
						
						--AND Page_1003_Property_Will_Be__Occupancy ='Primary Residence'
						)

Select 
	  [Loan #]
	, [Channel]
	, [Occupancy]
	, [LTV]
	, [Borowers Email]
	, row_number() over (partition by [Borowers Email] order by [Borowers Email])
	  [Duplicate Counter]
FROM all_cte ac
LEFT JOIN	(--***ALL THE SERVICING LOANS BELONGING TO A&D***
			SELECT 
				(SUBSTRING(LoanId, (LEN(LoanId)-(LEN(LoanId)-4)), LEN(LoanId))) [loanid] 
			FROM finastra.dbo.Status 
			WHERE PrimStat in (0,1,7,8) 
			and warning not in ('SOLD', 'PFF', 'Foreclosure')
			and LoanID not like '000000%'
			and LoanID not like '0008%'
			and LoanID not like '002%'
			and LoanID not like '9%'
			) sl
	ON ac.[Loan #]=sl.loanid
WHERE [Duplicate Counter]=1


'LOANS THAT ARE PREPARING TO BE PAID OFF,  '

	--select distinct statusdescription, lm.statusid from setups_loanstatus sls join  loan_main lm on lm.statusid=sls.statusid order by statusdescription 

	--select distinct Page_1003_Loan_Status_Lender from dm01.dbo.OC_1

	select * from [dbo].[retail_borrowers_emails]
		[Loan #]
		,count([Borowers Email])
	from [dbo].[retail_borrowers_emails]
	group by [Loan #]
	having count([Borowers Email])>1

	with email_cte
	as	(select 
			row_number()over (partition by [Loan #], [Borowers Email] order by [Loan #]) [Duplicate Counter]
			,[Loan #]
		from [dbo].[retail_borrowers_emails2]
	
		)

Select 
	a.[Loan #]
	,a.[Channel]
	,a.[Occupancy]
	,a.[LTV]
	, cte.[Duplicate Counter] [Borrower Email]
From email_cte cte  
INNER JOIN [dbo].[retail_borrowers_emails2] a
	ON cte.[Loan #]=a.[Loan #]
	where [Duplicate Counter]=1

	drop view [dbo].[retail_borrowers_emails]