--Servicing Analytic Report
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @MainDate DATE = '2023-06-30';
------------------
--Find date for SLS Report needed
------------------
	DECLARE @SLSDate DATETIME = '2023-07-01';
			--(
			--SELECT DataAsofDate
			--FROM [dm01].[dbo].[SERV_SLS_LastDateOfMonth]
			--WHERE YEAR(DataAsOfDate) = YEAR(@MainDate)
			--	AND MONTH(DataAsOfDate) = MONTH(@MainDate)
			--);

with SLSr
	AS (
		SELECT DataAsOfDate
			,ACCOUNT_NUMBER
			,DELQ_STATUS_OTS
			,ACCOUNT_NUMBER_PRIOR_SERVICER
			,INVESTOR_CODE
			,LOAN_SUB_TYPE
			,LOAN_TYPE_DESC
			,FICO_CURRENT
			,FICO_PRIOR_SERVICER
			,TERM_CURRENT
			,BALANCE_PRINCIPAL_CURRENT
			,ESCROW_BALANCE
			,PAYMENT_PI_AMOUNT_CURRENT
			,PAYMENT_TI_AMOUNT_CURRENT
			,PAYMENT_TOTAL_AMOUNT_NEXT
			,INTEREST_RATE_CURRENT
			,CLOSING_DATE
			,PAYMENT_DUE_DATE_FIRST
			,MATURITY_DATE_CURRENT
			,PAYMENT_DUE_DATE_NEXT
			,APPRAISAL_AMOUNT_ORIGINAL
			,APPRAISAL_AMOUNT_CURRENT
			,PROPERTY_STATE
			,PROPERTY_ZIP
			,PROPERTY_TYPE_CODE_DESC
			,LOAN_OCCUPANCY_CODE_DESC
			,PREPAY_PENALTY_DESC
			,PREPAY_PENALTY_EXPIRE_DATE_UF028
			,LOAN_CLTV
			,INTEREST_ONLY_INDICATOR
			,LOAN_PURPOSE_CODE_UF010_DESC
			,MERS_MIN
			,MI_RATE
			,INTEREST_RATE_INDEX_NUMBER
			,INTEREST_RATE_CHANGE_FREQUENCY_NEXT
			,PAYMENT_CHANGE_FREQUENCY_SUBSQT
			,INTEREST_RATE_CHANGE_DATE_NEXT
			,PAYMENT_PI_CHANGE_DATE_NEXT
			,INTEREST_RATE_CHANGE_FIRST_DATE
			,INTEREST_RATE_CHANGE_FIRST_MAX_DECREASE
			,INTEREST_RATE_CHANGE_FIRST_MAX_INCREASE
			,ARM_INTEREST_RATE_CEILING
			,ARM_INTEREST_RATE_FLOOR
			,ARM_PAYMENT_PI_BASE
			,INTEREST_RATE_ORIGINAL
		FROM [dm01].[dbo].[SLS_OAKTREE_Standard_Daily]
		WHERE DataAsOfDate = @SLSDate and DELQ_STATUS_OTS <> 'Service Release'
		)
		
, DMIr
	AS (
		SELECT d.LoanNumber
			,d.PrincipalBalancePresent
			,d.DueDateEffective
			,dp139.AnnualInterestRate as InterestRate
			,d.PIConstant
			,dp139.EscrowBalance
			,IIF(dp139.EscrowAdvanceBalance = 0, NULL, -dp139.EscrowAdvanceBalance) as EscrowAdvanceBalance
			,NULL AS DatePaid
			,d.AsOfDate
		FROM [dm01].[dbo].[SERV_DMI_Monthly_Report] d
		LEFT JOIN [dm01].[dbo].[SERV_DMI_P139_Monthly_Report] dp139 on d.LoanNumber = dp139.LoanNumber and d.InvestorCode = dp139.InvestorCode and d.AsOfDate = dp139.AsOfDate
		WHERE YEAR(d.AsOfDate) = YEAR(@MainDate)
			AND MONTH(d.AsOfDate) = MONTH(@MainDate)
		
		UNION ALL
		
		SELECT LoanNumber
			,NULL AS PrincipalBalancePresent
			,NULL AS DueDateEffective
			,NULL AS InterestRate
			,NULL AS PIConstant
			,NULL AS EscrowBalance
			,NULL AS EscrowAdvanceBalance
			,DatePaid
			,(SELECT MAX(AsOfDate) FROM [dm01].[dbo].[SERV_DMI_Monthly_Report]) as AsOfDate
		FROM [dm01].[dbo].[SERV_DMI_PaidOff_Monthly_Report]
		WHERE AsOfDate <= EOMONTH(@MainDate)
		)

, EndBalCalc 
	as (
		select h.LoanID, EndPrincipalBal
		from finastra.dbo.History h
		join (
			select a.*
			from (
				select 
					HistoryCounter
					, LoanID
					, ROW_NUMBER () OVER ( PARTITION BY LoanID ORDER BY TransactionDate desc, HistoryCounter desc ) as rn
				from finastra.dbo.History
				where cast(TransactionDate as date) <= @MainDate
				) a
		where a.rn = 1 ) a on a.LoanID = h.LoanID and a.HistoryCounter = h.HistoryCounter 
		)

, dscrdata 
	AS (
		select cast(loanid as varchar(20)) as LoanID, dscr
		from loan_main lm
		left join loan_postclosing lpc
			on lm.loanrecordid=lpc.loanrecordid and lpc.lenderdatabaseid=lm.lenderdatabaseid
		where lm.loanrecordid not in (
			SELECT *
			FROM dm01.dbo.integra_test_loans
			)
		AND YEAR(lpc.submissiondate) <> 1800 
		UNION
		select cast(OC_5.Loan_ID as varchar(20)) as LoanID, case when len(RTRIM(LTRIM(OC_5.Custom_Fields_DSCR_RSI_PITIA))) = 0 then 0 else cast(REPLACE(OC_5.Custom_Fields_DSCR_RSI_PITIA, ',', '') as float) end as dscr
		from dm01.dbo.OC_5 OC_5
		left join dm01.dbo.OC_4 oc4 on oc4.Loan_ID = OC_5.Loan_ID
		where oc4.Tracking_Submit_Date_only is not NULL and len(oc4.Tracking_Submit_Date_only)>0
	)

, Fr 
	AS (
		SELECT f.LoanID
			,ProfileDescription
			,StatusDesc
			,Warning
			,case when InvestorID = '05-15' then '05-015' else InvestorID end as InvestorID
			,InvestorName
			--,PrincipalBal
			, ebc.EndPrincipalBal as PrincipalBal
			,DueDate
			,InterestRate
			,MaturityDate
			,CreditScore
			,dd.dscr
		FROM [dm01].[dbo].[SERV_Finastra_Monthly_Report] f
		LEFT JOIN EndBalCalc ebc on ebc.LoanID = f.LoanID
		LEFT JOIN dscrdata dd on dd.LoanID = cast(f.LoanID as bigint)
		WHERE cast(AsOfDate AS DATE) = cast(DATEADD(d, 1, @MainDate) AS DATE)
			--where AsOfDate = @MainDate
			AND StatusDesc <> 'Pending'
		)

SELECT
	--SLSr.DataAsOfDate as [__SLS REPORT DATE],
	SLSr.ACCOUNT_NUMBER as [__SLS LOAN NUMBER],
	--DMIr.AsOfDate as [__DMI REPORT DATE],
	DMIr.LoanNumber as [__DMI LOAN NUMBER],
	CASE
		WHEN SLSr.ACCOUNT_NUMBER_PRIOR_SERVICER IS NOT NULL
			THEN (CASE 
					WHEN SLSr.DELQ_STATUS_OTS in ('Current', 'DQ 1-29', 'DQ 30-59', 'DQ 60-89', 'DQ 90-119', 'DQ 120+') 
						THEN 'SLS-Active' 
					ELSE CONCAT('SLS-', SLSr.DELQ_STATUS_OTS)
					END)
		--WHEN SRLoanData.ServicedByCode = '6'
		WHEN SRLoanData.ServicedByCode = '6' and DMIr.LoanNumber is not NULL 
			THEN (CASE 
					WHEN DMIr.DatePaid is not NULL
						THEN 'DMI-Paid in Full'
					ELSE 'DMI-Active'
					END)
		ELSE (CASE
				WHEN (Fr.StatusDesc = 'Active' and Fr.Warning = 'BK') THEN 'Bankruptcy'
				WHEN (Fr.StatusDesc = 'Active' and Fr.Warning = 'FCL') THEN 'Foreclosure'
				WHEN (Fr.StatusDesc = 'Active' and Fr.Warning = 'FRB') THEN 'Forebearance'
				WHEN Fr.StatusDesc like 'Pd-off%' THEN 'Paid in Full'
				WHEN Fr.StatusDesc like 'Liq%' THEN 'Liq'
				WHEN Fr.StatusDesc like 'Serv Rel%' THEN 'Sold'
				ELSE Fr.StatusDesc
				END)
		--ELSE (CASE
		--		WHEN Status.PrimStat = 0 THEN 'Pending'
		--		WHEN (Status.PrimStat = 1 and Status.Warning = 'BK') THEN 'Bankruptcy'
		--		WHEN (Status.PrimStat = 1 and Status.Warning = 'FCL') THEN 'Foreclosure'
		--		WHEN (Status.PrimStat = 1 and Status.Warning = 'FRB') THEN 'Forebearance'
		--		WHEN Status.PrimStat = 1 THEN 'Active'
		--		WHEN Status.PrimStat in (2, 3) THEN 'Paid in Full'
		--		WHEN Status.PrimStat in (4, 5, 6) THEN 'Liq'
		--		WHEN Status.PrimStat in (7, 8) THEN 'Sold'
		--		END)
		END as [__STATUS],
	@MainDate as [MSP LAST RUN DATE] --GETUTCDATE()
	, Fr.LoanID as [LOAN NUMBER]
	, CASE
		WHEN SLSr.ACCOUNT_NUMBER_PRIOR_SERVICER IS NOT NULL THEN 'SLS'
		WHEN SRLoanData.ServicedByCode = '6' and DMIr.LoanNumber is not NULL THEN 'DMI'
		ELSE 'In house'
		END AS [Servicer]
	, CASE
		WHEN SLSr.ACCOUNT_NUMBER_PRIOR_SERVICER IS NOT NULL
			THEN SLSr.BALANCE_PRINCIPAL_CURRENT
		WHEN SRLoanData.ServicedByCode = '6' and DMIr.LoanNumber is not NULL
			THEN DMIr.PrincipalBalancePresent
		ELSE Fr.PrincipalBal 
		END as [UPB]
	, CASE
		WHEN SLSr.ACCOUNT_NUMBER_PRIOR_SERVICER IS NOT NULL
			THEN CAST(SLSr.PAYMENT_DUE_DATE_NEXT as DATE)
		WHEN SRLoanData.ServicedByCode = '6' and DMIr.LoanNumber is not NULL
			THEN DMIr.DueDateEffective
		ELSE CAST(Fr.DueDate as DATE)
		END as [Next Due Date]

	,CASE 
		WHEN SLSr.ACCOUNT_NUMBER_PRIOR_SERVICER IS NOT NULL
			THEN (CASE 
					WHEN SLSr.DELQ_STATUS_OTS = 'DQ 1-29' THEN 'Current'
					WHEN SLSr.DELQ_STATUS_OTS = 'DQ 30-59' THEN 'DQ 30'
					WHEN SLSr.DELQ_STATUS_OTS = 'DQ 60-89' THEN 'DQ 60'
					WHEN SLSr.DELQ_STATUS_OTS = 'DQ 90-119' THEN 'DQ 90'
					ELSE SLSr.DELQ_STATUS_OTS
					END
					)
		WHEN Fr.Warning = 'FCL'
			THEN 'Foreclosure'
		WHEN Fr.Warning = 'BK'
			THEN 'Bankruptcy'
		WHEN SRLoanData.ServicedByCode = '6' and DMIr.LoanNumber is not NULL 
			THEN (
				CASE 
					WHEN DMIr.DatePaid is not NULL
						THEN 'Paid in Full'
					WHEN DATEDIFF(m, DMIr.DueDateEffective, @MainDate) < 1
						THEN 'Current'
					WHEN DATEDIFF(m, DMIr.DueDateEffective, @MainDate) = 1
						THEN 'DQ 30'
					WHEN DATEDIFF(m, DMIr.DueDateEffective, @MainDate) = 2
						THEN 'DQ 60'
					WHEN DATEDIFF(m, DMIr.DueDateEffective, @MainDate) = 3
						THEN 'DQ 90'
					ELSE 'DQ 120+'
					END
				)
		WHEN Fr.StatusDesc = 'Pd-off Prepaid'
			THEN 'Paid in Full'
		ELSE 
			(CASE
				WHEN Fr.StatusDesc IN (
					'Serv Rel - w/EOY'
					,'Serv Rel - w/o EOY'
					)
				THEN 'SERVICE TRANSFER-SOLD'
				ELSE (
					CASE 
						WHEN DATEDIFF(m, Fr.DueDate, @MainDate) < 1
							THEN 'Current'
						WHEN DATEDIFF(m, Fr.DueDate, @MainDate) = 1
							THEN 'DQ 30'
						WHEN DATEDIFF(m, Fr.DueDate, @MainDate) = 2
							THEN 'DQ 60'
						WHEN DATEDIFF(m, Fr.DueDate, @MainDate) = 3
							THEN 'DQ 90'
						ELSE 'DQ 120+'
						END
					)
				END
			)
		END AS [Status]
	--, Loan.LoanProfile
	, Fr.ProfileDescription as [LoanProfile]
	, CASE
		WHEN SLSr.ACCOUNT_NUMBER_PRIOR_SERVICER IS NOT NULL
			THEN SLSr.LOAN_PURPOSE_CODE_UF010_DESC
		ELSE 
			(
				CASE 
					when LoanPurpose.Name like 'Purchase %' then 'Purchase'
					when LoanPurpose.Name like 'Refinance %' then 'Refinance'
					when LoanPurpose.Name like 'Construct %' then 'Construct'
					else LoanPurpose.Name
					END
			)
		END as [LoanPurpose]
	, CASE 
					when LoanPurpose.Name like 'Purchase %' then 'Purchase'
					when LoanPurpose.Name like 'Refinance %' then 'Refinance'
					when LoanPurpose.Name like 'Construct %' then 'Construct'
					else LoanPurpose.Name
		END as [LoanPurpose111]
	, Property.OriginalLTV * 100 as [Original LTV]
	, CASE
		WHEN SLSr.ACCOUNT_NUMBER_PRIOR_SERVICER IS NOT NULL
			THEN SLSr.FICO_CURRENT --FICO_PRIOR_SERVICER
		ELSE Fr.CreditScore
		END as [FICO]
	,Fr.dscr as [DSCR]
	, CASE
		WHEN SLSr.ACCOUNT_NUMBER_PRIOR_SERVICER IS NOT NULL
			THEN SLSr.PROPERTY_STATE
		ELSE Property.State
		END as [State]

FROM
	Fr
LEFT JOIN finastra.dbo.Loan Loan ON Fr.LoanID = Loan.LoanID
LEFT JOIN finastra.dbo.SRLoanData SRLoanData ON Loan.LoanID = SRLoanData.LoanID
LEFT JOIN finastra.dbo.Property Property ON Loan.LoanID = Property.LoanID
LEFT JOIN finastra.dbo.LoanPurpose LoanPurpose ON Loan.LoanPurpose = LoanPurpose.Code
LEFT JOIN SLSr SLSr ON CAST(Loan.LoanID as bigint) = SLSr.ACCOUNT_NUMBER_PRIOR_SERVICER
LEFT JOIN DMIr DMIr ON SRLoanData.SRLoanNumber = CAST(DMIr.LoanNumber as VARCHAR) and SRLoanData.ServicedByCode = '6'

order by Fr.LoanID

--WHERE 
--	(CASE
--		WHEN SLSr.ACCOUNT_NUMBER_PRIOR_SERVICER IS NOT NULL
--			THEN (CASE 
--					WHEN SLSr.DELQ_STATUS_MBA in ('Current', 'DQ 30', 'DQ 60', 'DQ 90') 
--						THEN 'SLS-Active' 
--					ELSE CONCAT('SLS-', SLSr.DELQ_STATUS_MBA)
--					END)
--		--WHEN SRLoanData.ServicedByCode = '6'
--		WHEN Fr.Warning = 'DMI'
--			THEN (CASE 
--					WHEN DMIr.DatePaid is not NULL
--						THEN 'DMI-Paid in Full'
--					ELSE 'DMI-Active'
--					END)
--		ELSE (CASE
--				WHEN (Fr.StatusDesc = 'Active' and Fr.Warning = 'BK') THEN 'Bankruptcy'
--				WHEN (Fr.StatusDesc = 'Active' and Fr.Warning = 'FCL') THEN 'Foreclosure'
--				WHEN (Fr.StatusDesc = 'Active' and Fr.Warning = 'FRB') THEN 'Forebearance'
--				WHEN Fr.StatusDesc like 'Pd-off%' THEN 'Paid in Full'
--				WHEN Fr.StatusDesc like 'Liq%' THEN 'Liq'
--				WHEN Fr.StatusDesc like 'Serv Rel%' THEN 'Sold'
--				ELSE Fr.StatusDesc
--				END)
--		--ELSE (CASE
--		--		WHEN Status.PrimStat = 0 THEN 'Pending'
--		--		WHEN (Status.PrimStat = 1 and Status.Warning = 'BK') THEN 'Bankruptcy'
--		--		WHEN (Status.PrimStat = 1 and Status.Warning = 'FCL') THEN 'Foreclosure'
--		--		WHEN (Status.PrimStat = 1 and Status.Warning = 'FRB') THEN 'Forebearance'
--		--		WHEN Status.PrimStat = 1 THEN 'Active'
--		--		WHEN Status.PrimStat in (2, 3) THEN 'Paid in Full'
--		--		WHEN Status.PrimStat in (4, 5, 6) THEN 'Liq'
--		--		WHEN Status.PrimStat in (7, 8) THEN 'Sold'
--		--		END)
--		END) not in ('SLS-Paid in Full', 'DMI-Paid in Full', 'Paid in Full', 'Sold', 'Pending')
--		and Fr.ProfileDescription not like '%FHA%' and Fr.ProfileDescription not like '%VA%'

--select distinct LOAN_PURPOSE_CODE_UF010_DESC-- DELQ_STATUS_OTS, DELQ_STATUS_MBA--DataAsOfDate, ACCOUNT_NUMBER_PRIOR_SERVICER, DELQ_STATUS_MBA, DELQ_STATUS_OTS
--from dm01.dbo.SLS_OAKTREE_Standard_Daily
--where DataAsOfDate = '2023-07-01'