--use dm01
--select * 
--from [dbo].[SERV_DMI_Monthly_Report]
--where AsOfDate='2023-08-31'

--select * 
--from [dbo].[SERV_DMI_PaidOff_Monthly_Report]
--where AsOfDate='2023-08-31'

--MCT Report
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @MainDate DATE = '2023-08-31';
------------------
--Find date for SLS Report needed
------------------
	DECLARE @SLSDate DATETIME = --'2023-07-01';
			(
			SELECT DataAsofDate
			FROM [dm01].[dbo].[SERV_SLS_LastDateOfMonth]
			WHERE YEAR(DataAsOfDate) = YEAR(@MainDate)
				AND MONTH(DataAsOfDate) = MONTH(@MainDate)
			);

with SLSr
	AS (
		SELECT DataAsOfDate
			,ACCOUNT_NUMBER
			,DELQ_STATUS_MBA
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
		WHERE DataAsOfDate = @SLSDate and DELQ_STATUS_MBA <> 'Service Release'
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
		from History h
		join (
			select a.*
			from (
				select 
					HistoryCounter
					, LoanID
					, ROW_NUMBER () OVER ( PARTITION BY LoanID ORDER BY TransactionDate desc, HistoryCounter desc ) as rn
				from History
				where cast(TransactionDate as date) <= @MainDate
				) a
		where a.rn = 1 ) a on a.LoanID = h.LoanID and a.HistoryCounter = h.HistoryCounter 
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
		FROM [dm01].[dbo].[SERV_Finastra_Monthly_Report] f
		LEFT JOIN EndBalCalc ebc on ebc.LoanID = f.LoanID
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
					WHEN SLSr.DELQ_STATUS_MBA in ('Current', 'DQ 30', 'DQ 60', 'DQ 90') 
						THEN 'SLS-Active' 
					ELSE CONCAT('SLS-', SLSr.DELQ_STATUS_MBA)
					END)
		--WHEN SRLoanData.ServicedByCode = '6'
		WHEN Fr.Warning = 'DMI'
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
	--, Loan.LoanProfile
	, Fr.ProfileDescription as [ASSET TYPE]
	, CASE
		WHEN SLSr.ACCOUNT_NUMBER_PRIOR_SERVICER IS NOT NULL
			THEN CAST(SLSr.INVESTOR_CODE as VARCHAR)
		ELSE CAST(Fr.InvestorID as VARCHAR)
		END AS [INVESTOR ID]
	, Fr.InvestorName as [__Investor Name]
	, NULL as [CATEGORY CODE]
	, CASE
		WHEN SLSr.ACCOUNT_NUMBER_PRIOR_SERVICER IS NOT NULL
			THEN (CASE
					WHEN SLSr.INVESTOR_CODE in (689, 690, 829, 830, 831, 832, 841, 842, 845, 846, 642, 643, 669, 670)
						THEN 'Schedule / Schedule'
					WHEN SLSr.INVESTOR_CODE in (2286, 2239, 2235, 2236)
						THEN 'Actual / Actual'
					ELSE NULL
					END)
		WHEN SRLoanData.ServicedByCode = '6' and DMIr.LoanNumber is not NULL
			THEN 'Actual / Actual'
		ELSE (CASE 
				WHEN Fr.InvestorID = '06-001'
					THEN 'Actual / Schedule'
				WHEN Fr.InvestorID in ('05-007', '05-008', '05-009', '05-010', '05-011', '05-012', '05-013', '05-014', '05-015', '05-016',
											'03-001', '03-002', '03-003', '03-004', '03-007', '03-009', '03-010', '03-011', '03-005', 
											'03-012', '03-013', '03-008', '03-014', '03-015', '03-006', '03-016', '03-017', '03-018')
					THEN 'Schedule / Schedule'
				WHEN Fr.InvestorID in ('02-001', '02-004', '02-005', '02-007', '02-002', '01-009', '01-010', '01-022', '01-002', 
											'01-013', '01-004', '01-007', '01-008', '01-020', '01-005', '01-012', '01-011', '01-003')
					THEN 'Actual / Actual'
				ELSE NULL
				END)
		END as [Investor Remittance Type]
	, CASE
		WHEN SLSr.ACCOUNT_NUMBER_PRIOR_SERVICER IS NOT NULL
			THEN 
				(CASE SLSr.LOAN_SUB_TYPE
					WHEN 'ARM (Adjustable Rate Mortgage)' THEN 'Adjustable'
					ELSE 'Fix'
					END )
		ELSE
			(CASE Loan.ARMLoan
				WHEN 1 THEN 'Adjustable'
				ELSE 'Fix'
				END )
		END as [ARM INDICATOR]
	, NULL as [ARM INDICATOR DESCRIPTION]
	, NULL as [HI TYPE]
	, NULL as [HI TYPE DESCRIPTION]
	--, Loan.LoanType
	, CASE
		WHEN SLSr.ACCOUNT_NUMBER_PRIOR_SERVICER IS NOT NULL
			THEN SLSr.LOAN_TYPE_DESC
		ELSE TypeDescription.Description 
		END as [LO TYPE]
	, NULL as [LO TYPE DESCRIPTION]
	, NULL as [CS BORR CREDIT QUALITY CODE (FICO)] --SLSr.FICO_CURRENT
	, CASE
		WHEN SLSr.ACCOUNT_NUMBER_PRIOR_SERVICER IS NOT NULL
			THEN SLSr.FICO_CURRENT --FICO_PRIOR_SERVICER
		ELSE Fr.CreditScore
		END as [CS BORR ORIG CREDIT QLTY CODE (FICO Orig)]
	, CASE
		WHEN SLSr.ACCOUNT_NUMBER_PRIOR_SERVICER IS NOT NULL
			THEN SLSr.TERM_CURRENT
		ELSE Loan.OriginalTerm
		END as [LOAN TERM]
	, Loan.OriginalAmt as [ORIGINAL MORTGAGE AMOUNT]
	, CASE
		WHEN SLSr.ACCOUNT_NUMBER_PRIOR_SERVICER IS NOT NULL
			THEN SLSr.BALANCE_PRINCIPAL_CURRENT
		WHEN SRLoanData.ServicedByCode = '6' and DMIr.LoanNumber is not NULL
			THEN DMIr.PrincipalBalancePresent
		ELSE Fr.PrincipalBal 
		END as [Current UPB]
	, CASE
		WHEN SLSr.ACCOUNT_NUMBER_PRIOR_SERVICER IS NOT NULL
			THEN SLSr.ESCROW_BALANCE
		WHEN SRLoanData.ServicedByCode = '6' and DMIr.LoanNumber is not NULL
			THEN DMIr.EscrowBalance
		ELSE Loan.EscrowBal
		END as [ESCROW BALANCE]
	, CASE
		WHEN SLSr.ACCOUNT_NUMBER_PRIOR_SERVICER IS NOT NULL and SLSr.ESCROW_BALANCE < 0
			THEN SLSr.ESCROW_BALANCE
		WHEN SRLoanData.ServicedByCode = '6' and DMIr.LoanNumber is not NULL
			THEN DMIr.EscrowAdvanceBalance
		ELSE (CASE 
				WHEN Loan.EscrowBal < 0 
					THEN Loan.EscrowBal 
				ELSE NULL 
				END)
		END as [ESCROW ADVANCE BALANCE]
	, NULL as [NON REC CORP ADVANCE BALANCE]
	, NULL as [RECOVER CORP ADVANCE BALANCE]
	, NULL as [THIRD PARTY RECOVERABLE CA BAL]
	, CASE
		WHEN SLSr.ACCOUNT_NUMBER_PRIOR_SERVICER IS NOT NULL
			THEN SLSr.PAYMENT_PI_AMOUNT_CURRENT
		WHEN SRLoanData.ServicedByCode = '6' and DMIr.LoanNumber is not NULL
			THEN DMIr.PIConstant
		ELSE Loan.PIPmt 
		END as [Monthly P&I Amount]
	, CASE
		WHEN SLSr.ACCOUNT_NUMBER_PRIOR_SERVICER IS NOT NULL
			THEN SLSr.PAYMENT_TI_AMOUNT_CURRENT
		ELSE Loan.EscrowPmt 
		END as [Monthly T&I Amount]
	, CASE
		WHEN SLSr.ACCOUNT_NUMBER_PRIOR_SERVICER IS NOT NULL
			THEN SLSr.PAYMENT_TOTAL_AMOUNT_NEXT
		WHEN SRLoanData.ServicedByCode = '6' and DMIr.LoanNumber is not NULL
			THEN (DMIr.PIConstant + Loan.EscrowPmt)
		ELSE (Loan.PIPmt + Loan.EscrowPmt) 
		END as [Monthly Total Payment]
	, CASE
		WHEN SLSr.ACCOUNT_NUMBER_PRIOR_SERVICER IS NOT NULL
			THEN SLSr.INTEREST_RATE_CURRENT
		WHEN SRLoanData.ServicedByCode = '6' and DMIr.LoanNumber is not NULL
			THEN DMIr.InterestRate * 100
		ELSE Fr.InterestRate * 100
		END as [ANNUAL INTEREST RATE]
	, CASE
		WHEN SLSr.ACCOUNT_NUMBER_PRIOR_SERVICER IS NOT NULL
			THEN (CASE
					WHEN SLSr.INVESTOR_CODE in (689, 690, 829, 830, 831, 832, 841, 842, 845, 846)
						THEN 0.5
					WHEN SLSr.INVESTOR_CODE in (642, 643, 669, 670, 2286, 2239, 2235, 2236)
						THEN 0.25
					ELSE NULL
					END)
		WHEN SRLoanData.ServicedByCode = '6' and DMIr.LoanNumber is not NULL
			THEN 0.25
		ELSE (CASE 
				WHEN Fr.InvestorID in ('06-001', '03-001', '03-002', '03-003', '03-004', '03-007', '03-009', '03-010', '03-011'
											, '03-005', '03-012', '03-013', '03-008', '03-014', '03-015', '03-006', '03-016', '03-017', '03-018')
					THEN 0.25
				WHEN Fr.InvestorID in ('05-007', '05-008', '02-001', '02-004', '02-005', '02-007', '02-002', '01-008')						
					THEN 0.5
				WHEN Fr.InvestorID in ('05-009', '05-010', '05-011', '05-012', '05-013', '05-014', '05-015', '05-016')
					THEN 0.35
				WHEN Fr.InvestorID = '01-009'
					THEN 3.00
				WHEN Fr.InvestorID in ('01-010', '01-003')
					THEN 0.00
				WHEN Fr.InvestorID in ('01-013', '01-020', '01-005')
					THEN 1.00	
				WHEN Fr.InvestorID = '01-004'
					THEN 0.75
				WHEN Fr.InvestorID = '01-007'
					THEN 2.00
				WHEN Fr.InvestorID = '01-011'
					THEN 1.50
				ELSE NULL
				END)
		END as [Gross Service Fee Rate]
	, NULL as [GUAR FEE AFTER BUYUP DOWN FC]
	, CASE
		WHEN SLSr.ACCOUNT_NUMBER_PRIOR_SERVICER IS NOT NULL
			THEN (CASE
					WHEN SLSr.INVESTOR_CODE in (689, 690, 829, 830, 831, 832, 841, 842, 845, 846)
						THEN SLSr.INTEREST_RATE_CURRENT - 0.5
					WHEN SLSr.INVESTOR_CODE in (642, 643, 669, 670, 2286, 2239, 2235, 2236)
						THEN SLSr.INTEREST_RATE_CURRENT - 0.25
					ELSE NULL
					END)
		WHEN SRLoanData.ServicedByCode = '6' and DMIr.LoanNumber is not NULL
			THEN DMIr.InterestRate * 100 - 0.25
		ELSE (CASE 
				WHEN Fr.InvestorID in ('06-001', '03-001', '03-002', '03-003', '03-004', '03-007', '03-009', '03-010', '03-011'
											, '03-005', '03-012', '03-013', '03-008', '03-014', '03-015', '03-006', '03-016', '03-017', '03-018')
					THEN Fr.InterestRate * 100 - 0.25
				WHEN Fr.InvestorID in ('05-007', '05-008', '02-001', '02-004', '02-005', '02-007', '02-002', '01-008')						
					THEN Fr.InterestRate * 100 - 0.5
				WHEN Fr.InvestorID in ('05-009', '05-010', '05-011', '05-012', '05-013', '05-014', '05-015', '05-016')
					THEN Fr.InterestRate * 100 - 0.35
				WHEN Fr.InvestorID = '01-009'
					THEN Fr.InterestRate * 100 - 3.00
				WHEN Fr.InvestorID in ('01-010', '01-003')
					THEN Fr.InterestRate * 100 - 0.00
				WHEN Fr.InvestorID in ('01-013', '01-020', '01-005')
					THEN Fr.InterestRate * 100 - 1.00	
				WHEN Fr.InvestorID = '01-004'
					THEN Fr.InterestRate * 100 - 0.75
				WHEN Fr.InvestorID = '01-007'
					THEN Fr.InterestRate * 100 - 2.00
				WHEN Fr.InvestorID = '01-011'
					THEN Fr.InterestRate * 100 - 1.50
				ELSE NULL
				END)
		END as [PASS THRU RATE]
	, CASE
		WHEN SLSr.ACCOUNT_NUMBER_PRIOR_SERVICER IS NOT NULL
			THEN (CASE
					WHEN SLSr.INVESTOR_CODE in (689, 690, 829, 830, 831, 832, 841, 842, 845, 846)
						THEN 0.5
					WHEN SLSr.INVESTOR_CODE in (642, 643, 669, 670, 2286, 2239, 2235, 2236)
						THEN 0.25
					ELSE NULL
					END)
		WHEN SRLoanData.ServicedByCode = '6' and DMIr.LoanNumber is not NULL
			THEN 0.25
		ELSE (CASE 
				WHEN Fr.InvestorID in ('06-001', '03-001', '03-002', '03-003', '03-004', '03-007', '03-009', '03-010', '03-011'
											, '03-005', '03-012', '03-013', '03-008', '03-014', '03-015', '03-006', '03-016', '03-017', '03-018')
					THEN 0.25
				WHEN Fr.InvestorID in ('05-007', '05-008', '02-001', '02-004', '02-005', '02-007', '02-002', '01-008')						
					THEN 0.5
				WHEN Fr.InvestorID in ('05-009', '05-010', '05-011', '05-012', '05-013', '05-014', '05-015', '05-016')
					THEN 0.35
				WHEN Fr.InvestorID = '01-009'
					THEN 3.00
				WHEN Fr.InvestorID in ('01-010', '01-003')
					THEN 0.00
				WHEN Fr.InvestorID in ('01-013', '01-020', '01-005')
					THEN 1.00	
				WHEN Fr.InvestorID = '01-004'
					THEN 0.75
				WHEN Fr.InvestorID = '01-007'
					THEN 2.00
				WHEN Fr.InvestorID = '01-011'
					THEN 1.50
				ELSE NULL
				END)
		END as [NET SERV FEE]
	, CASE
		WHEN SLSr.ACCOUNT_NUMBER_PRIOR_SERVICER IS NOT NULL
			THEN CAST(SLSr.CLOSING_DATE as DATE)
		ELSE CAST(Loan.LoanCloseDate as DATE)
		END as [LOAN CLOSING DATE]
	, CASE
		WHEN SLSr.ACCOUNT_NUMBER_PRIOR_SERVICER IS NOT NULL
			THEN CAST(SLSr.PAYMENT_DUE_DATE_FIRST as DATE)
		ELSE CAST(Loan.FirstDueDate as DATE)
		END as [FIRST DUE DATE]
	, CASE
		WHEN SLSr.ACCOUNT_NUMBER_PRIOR_SERVICER IS NOT NULL
			THEN CAST(SLSr.MATURITY_DATE_CURRENT as DATE)
		ELSE CAST(Fr.MaturityDate as DATE)
		END as [LOAN MATURES DATE]
	, CASE
		WHEN SLSr.ACCOUNT_NUMBER_PRIOR_SERVICER IS NOT NULL
			THEN CAST(SLSr.PAYMENT_DUE_DATE_NEXT as DATE)
		WHEN SRLoanData.ServicedByCode = '6' and DMIr.LoanNumber is not NULL
			THEN NULL
		ELSE CAST(Fr.DueDate as DATE)
		END as [NEXT PAYMENT DUE DATE]		
	, CASE
		WHEN SLSr.ACCOUNT_NUMBER_PRIOR_SERVICER IS NOT NULL
			THEN SLSr.APPRAISAL_AMOUNT_ORIGINAL
		ELSE Property.AppraisalValue 
		END as [ORIGINAL PROPERTY VALUE AMOUNT]
	, CASE
		WHEN SLSr.ACCOUNT_NUMBER_PRIOR_SERVICER IS NOT NULL
			THEN SLSr.APPRAISAL_AMOUNT_CURRENT
		ELSE Property.CurrentAppValue 
		END as [PROPERTY VALUE AMOUNT]
	, CASE
		WHEN SLSr.ACCOUNT_NUMBER_PRIOR_SERVICER IS NOT NULL
			THEN SLSr.PROPERTY_STATE
		ELSE Property.State
		END as [PROPERTY ALPHA STATE CODE]
	, CASE
		WHEN SLSr.ACCOUNT_NUMBER_PRIOR_SERVICER IS NOT NULL
			THEN CAST(SLSr.PROPERTY_ZIP as VARCHAR)
		ELSE CAST(Property.Zip AS VARCHAR)
		END as [PROPERTY ZIP CODE]
	, CASE
		WHEN SLSr.ACCOUNT_NUMBER_PRIOR_SERVICER IS NOT NULL
			THEN SLSr.PROPERTY_TYPE_CODE_DESC
		ELSE PropertyType.Name
		END as [PROPERTY TYPE]
	, NULL as [PROPERTY TYPE DESCRIPTION]
	, CASE
		WHEN SLSr.ACCOUNT_NUMBER_PRIOR_SERVICER IS NOT NULL
			THEN SLSr.LOAN_OCCUPANCY_CODE_DESC
		ELSE Occupancy.Description
		END as [OCCUPANCY CODE]
	, NULL as [OCCUPANCY CODE DESCRIPTION]
	, NULL as [BANKRUPTCY CODE]
	, NULL as [BANKRUPTCY CODE DESCRIPTION]
	, NULL as [FORECLOSURE STOP CODE]
	, NULL as [FORECLOSURE STOP CODE DESCRIPTION]
	, NULL as [LOSS MITIGATION CODE]
	, NULL as [LOSS MITIGATION CODE DESCRIPTION]
	, CASE
		WHEN SLSr.ACCOUNT_NUMBER_PRIOR_SERVICER IS NOT NULL
			THEN 
				( CASE
					WHEN LEN(SLSr.PREPAY_PENALTY_DESC) = 0 or SLSr.PREPAY_PENALTY_DESC is NULL
						THEN 'No'
					ELSE 'Yes'
					END )
		ELSE 
			( CASE
				WHEN PrepaymentPenalty.PrepayDescription  = 'No Prepayment'
					THEN 'No'
				ELSE 'Yes'
				END )
		END as [PREPAY PENALTY INDICATOR]
	, CASE
		WHEN SLSr.ACCOUNT_NUMBER_PRIOR_SERVICER IS NOT NULL and LEN(SLSr.PREPAY_PENALTY_DESC) <> 0 and SLSr.PREPAY_PENALTY_DESC is not NULL
			THEN SLSr.PREPAY_PENALTY_DESC
		ELSE
			( CASE
				WHEN PrepaymentPenalty.PrepayDescription = 'No Prepayment'
					THEN NULL
				ELSE CONCAT(Loan.PrepayYears * 12, ' months')
				END )
		END as [PREPAY PENALTY Schedule]
	, CASE
		WHEN SLSr.ACCOUNT_NUMBER_PRIOR_SERVICER IS NOT NULL 
			THEN 
				( CASE
					WHEN LEN(SLSr.PREPAY_PENALTY_DESC) <> 0 and SLSr.PREPAY_PENALTY_DESC is not NULL
						THEN SLSr.PREPAY_PENALTY_DESC
					END )
		ELSE 
			( CASE
				WHEN PrepaymentPenalty.PrepayDescription = 'No Prepayment'
					THEN NULL
				ELSE PrepaymentPenalty.PrepayDescription
				END )
		END as [PREPAY PENALTY Term]
	, CASE
		WHEN SLSr.ACCOUNT_NUMBER_PRIOR_SERVICER IS NOT NULL 
			THEN 
				( CASE
					WHEN LEN(SLSr.PREPAY_PENALTY_DESC) <> 0 and SLSr.PREPAY_PENALTY_DESC is not NULL
						THEN CAST(SLSr.PREPAY_PENALTY_EXPIRE_DATE_UF028 as DATE)
						END )
		ELSE 
			( CASE
				WHEN PrepaymentPenalty.PrepayDescription <> 'No Prepayment'
					THEN CAST(DATEADD(year, Loan.PrepayYears, Loan.FirstDueDate) as DATE)
				ELSE NULL 
				END )
		END as [PREPAY PENALTY Expiration Date]
	, Property.OriginalLTV * 100 as [ORIGINAL LOAN TO VALUE RATIO]
	, CASE
		WHEN SLSr.ACCOUNT_NUMBER_PRIOR_SERVICER IS NOT NULL
			THEN
				( CASE WHEN (SLSr.APPRAISAL_AMOUNT_CURRENT <> 0 and SLSr.BALANCE_PRINCIPAL_CURRENT <> 0)
						THEN SLSr.BALANCE_PRINCIPAL_CURRENT * 100 / SLSr.APPRAISAL_AMOUNT_CURRENT
					ELSE NULL END)
		ELSE 
			( CASE WHEN (Property.CurrentAppValue <> 0 and Fr.PrincipalBal <> 0)
						THEN Fr.PrincipalBal * 100 / Property.CurrentAppValue
					ELSE NULL END)
		END as [LOAN TO VALUE RATIO]
	, CASE
		WHEN SLSr.ACCOUNT_NUMBER_PRIOR_SERVICER IS NOT NULL
			THEN IIF(SLSr.INTEREST_ONLY_INDICATOR = 'Y', 'Yes', 'No')
		ELSE
			( CASE
				WHEN Loan.IntOnlyTerm <> 0 and Loan.IntOnlyTerm is not NULL
					THEN 'Yes'
				ELSE 'No'
				END )
		END as [Interest Only Indicator]
	, CASE
		WHEN SLSr.ACCOUNT_NUMBER_PRIOR_SERVICER IS NOT NULL
			THEN 0
		ELSE Loan.IntOnlyTerm 
		END as [Interest Only Term]
	, CASE
		WHEN SLSr.ACCOUNT_NUMBER_PRIOR_SERVICER IS NOT NULL
			THEN NULL
		ELSE 
			( CASE
				WHEN Loan.IntOnlyTerm = 0 or Loan.IntOnlyTerm is NULL 
					THEN NULL
				ELSE CAST(DATEADD(month, Loan.IntOnlyTerm, Loan.FirstDueDate) as DATE) 
				END )
		END as [INTEREST ONLY EXPIRE DATE]
	, CASE
		WHEN SLSr.ACCOUNT_NUMBER_PRIOR_SERVICER IS NOT NULL
			THEN SLSr.LOAN_PURPOSE_CODE_UF010_DESC
		ELSE LoanPurpose.Name
		END as [LOAN PURPOSE CODE]
	, NULL as [LOAN PURPOSE CODE DESCRIPTION]
	, Property.NumOfUnits as [NUMBER OF UNITS]
	, CASE
		WHEN SLSr.ACCOUNT_NUMBER_PRIOR_SERVICER IS NOT NULL
			THEN SLSr.MERS_MIN--IIF(SLSr.MERS_MIN is NULL, NULL, CONCAT('''',SLSr.MERS_MIN))
		ELSE LoanIdentity.MERSNum--IIF(LoanIdentity.MERSNum is NULL, NULL, CONCAT('''',LoanIdentity.MERSNum))
		END as [MERS ID]
	, --CASE
	--	WHEN SLSr.ACCOUNT_NUMBER_PRIOR_SERVICER IS NOT NULL
	--		THEN SLSr.MI_RATE
	--	ELSE NULL
	--	END
		NULL as [PMI RATE]
	, NULL as [MORTGAGE INSURANCE PAYEE] --MIPayee.NameLine1
	, NULL as [ARM IR MARGIN RATE]
	, ARM.ARMTemplate as [ARM PLAN ID]
	, NULL as [ARM PLAN ID DESCRIPTION]
	, CASE
		WHEN SLSr.ACCOUNT_NUMBER_PRIOR_SERVICER IS NOT NULL
			THEN SLSr.INTEREST_RATE_INDEX_NUMBER
		ELSE ARM.Index_  --ARMIndex.Name
		END as [ARM INDEX CODE 1]
	, NULL as [ARM INDEX CODE 1 DESCRIPTION]
	, CASE
		WHEN SLSr.ACCOUNT_NUMBER_PRIOR_SERVICER IS NOT NULL
			THEN SLSr.INTEREST_RATE_CHANGE_FREQUENCY_NEXT
		ELSE ARM.RateChgFrequency
		END as [ARM IR CHANGE PERIOD]
	, CASE
		WHEN SLSr.ACCOUNT_NUMBER_PRIOR_SERVICER IS NOT NULL
			THEN SLSr.PAYMENT_CHANGE_FREQUENCY_SUBSQT
		ELSE ARM.PIChgFrequency
		END as [ARM PI CHANGE PERIOD]
	, CASE
		WHEN SLSr.ACCOUNT_NUMBER_PRIOR_SERVICER IS NOT NULL
			THEN CAST(SLSr.INTEREST_RATE_CHANGE_DATE_NEXT as DATE)
		ELSE CAST(ARM.NextRateChgDate as DATE)
		END as [ARM NEXT IR EFFECTIVE DATE]
	, CASE
		WHEN SLSr.ACCOUNT_NUMBER_PRIOR_SERVICER IS NOT NULL
			THEN CAST(SLSr.PAYMENT_PI_CHANGE_DATE_NEXT as DATE)
		ELSE CAST(ARM.NextPIChgDate as DATE)
		END as [ARM NEXT PI EFFECTIVE DATE]
	, CASE
		WHEN SLSr.ACCOUNT_NUMBER_PRIOR_SERVICER IS NOT NULL
			THEN CAST(SLSr.INTEREST_RATE_CHANGE_FIRST_DATE as DATE)
		ELSE CAST(ARM.FrstRateChgDate as DATE)
		END as [ARM First Change DATE]
	, CASE
		WHEN SLSr.ACCOUNT_NUMBER_PRIOR_SERVICER IS NOT NULL
			THEN SLSr.INTEREST_RATE_CHANGE_FIRST_MAX_DECREASE
		ELSE NULL
		END as [ARM IR MAX DECREASE RATE]
	, CASE
		WHEN SLSr.ACCOUNT_NUMBER_PRIOR_SERVICER IS NOT NULL
			THEN SLSr.INTEREST_RATE_CHANGE_FIRST_MAX_INCREASE
		ELSE NULL
		END as [ARM IR MAX INCREASE RATE]
	, CASE
		WHEN SLSr.ACCOUNT_NUMBER_PRIOR_SERVICER IS NOT NULL
			THEN SLSr.ARM_INTEREST_RATE_CEILING
		ELSE NULL
		END as [ARM IR MAX LIFE CEILING RATE]
	, ARM.LifeRateDecrease as [ARM IR MAX LIFE DECR RATE]
	, CASE
		WHEN SLSr.ACCOUNT_NUMBER_PRIOR_SERVICER IS NOT NULL
			THEN SLSr.ARM_INTEREST_RATE_FLOOR
		ELSE ARM.FloorRate
		END as [ARM IR MAX LIFE FLOOR RATE]
	, ARM.LifeRateIncrease as [ARM IR MAX LIFE INCR RATE]
	, CASE
		WHEN SLSr.ACCOUNT_NUMBER_PRIOR_SERVICER IS NOT NULL
			THEN SLSr.ARM_PAYMENT_PI_BASE
		ELSE ARM.OriginalPIPmt
		END as [Original Monthly P&I (If ARM Loan)]
	, CASE
		WHEN SLSr.ACCOUNT_NUMBER_PRIOR_SERVICER IS NOT NULL
			THEN SLSr.INTEREST_RATE_ORIGINAL
		ELSE Fr.InterestRate * 100 --ARM.OriginalIntRate * 100
		END as [Original Interest Rate (If ARM Loan)]
	, DocType.Description as [DocumentType]
	, NULL as [VA IRRRL Indicator]
	, NULL as [Jumbo Loan Indicator]
	, NULL as [FHA Streamlined Flag]
	, NULL as [MBS Pool Number]
	, NULL as [Harp Loan Indicator]
	, NULL as [LN MOD STATUS CODE]
	, NULL as [LN MOD STATUS CODE DESCRIPTION]
	, CAST(Loan.ModificationDate as DATE) as [LN MOD DATE]
	, NULL as [LN MOD CODE]
	, NULL as [LN MOD CODE DESCRIPTION]
	, NULL as [MOD INFO BEFORE PRIN BALANCE]
	, NULL as [MOD INFO AFTER PRIN BALANCE]
	, NULL as [MOD INFO BEFORE INTEREST RATE]
	, NULL as [MOD INFO AFTER INTEREST RATE]
	, NULL as [MOD INFO BEFORE DUE DATE]
	, NULL as [MOD INFO AFTER DUE DATE]
	, NULL as [MS STEP NUMBER]
	, NULL as [MS STEP EFFECTIVE DATE]
	, NULL as [MS STEP INTEREST RATE]
	, NULL as [MS STEP PI AMOUNT]

FROM
	Fr
LEFT JOIN dbo.Loan Loan ON Fr.LoanID = Loan.LoanID
LEFT JOIN dbo.SRLoanData SRLoanData ON Loan.LoanID = SRLoanData.LoanID
INNER JOIN dbo.Status Status ON Loan.LoanID = Status.LoanID
LEFT JOIN dbo.SystemTypes StatusDescription ON Status.PrimStat = StatusDescription.Code AND StatusDescription.FieldName = 'PrimStat'
INNER JOIN dbo.LoanIdentity LoanIdentity ON Loan.LoanID = LoanIdentity.LoanID
LEFT JOIN dbo.Property Property ON Loan.LoanID = Property.LoanID
LEFT JOIN dbo.PropertyType PropertyType ON Property.PropertyType = PropertyType.Code
LEFT JOIN dbo.SystemTypes Occupancy ON Property.Occupancy = Occupancy.Code AND Occupancy.FieldName = 'Occupancy'
LEFT JOIN dbo.PrepaymentPenalty PrepaymentPenalty ON Loan.PrepayPenalty = PrepaymentPenalty.PrepayCode
LEFT JOIN dbo.LoanPurpose LoanPurpose ON Loan.LoanPurpose = LoanPurpose.Code
LEFT JOIN dbo.Insurance MI ON Loan.LoanID = MI.LoanID and MI.Type = 4
left join dbo.Payee MIPayee on MIPayee.PayeeID = MI.InsCo and MIPayee.PayeeIndicator = 1
LEFT JOIN dbo.SystemTypes DocType ON Loan.DocumentationType = DocType.Code AND DocType.FieldName = 'DocumentationType'
LEFT JOIN dbo.SystemTypes TypeDescription ON Loan.LoanType = TypeDescription.Code AND TypeDescription.FieldName = 'LoanType'

LEFT JOIN dbo.ARM ARM ON Loan.LoanID = ARM.LoanID
LEFT JOIN dbo.Index_ ARMIndex on ARMIndex.Code = ARM.Index_
LEFT JOIN SLSr SLSr ON CAST(Loan.LoanID as bigint) = SLSr.ACCOUNT_NUMBER_PRIOR_SERVICER
LEFT JOIN DMIr DMIr ON SRLoanData.SRLoanNumber = CAST(DMIr.LoanNumber as VARCHAR) and SRLoanData.ServicedByCode = '6'

order by Fr.LoanID