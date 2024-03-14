
	--DECLARE @FinDates AS TABLE
	--(AsOfDate DATETIME NOT NULL PRIMARY KEY,
	-- SourceName varchar(50) NOT NULL,
	-- OrderNum INT NOT NULL)
	--INSERT INTO @FinDates ( AsOfDate, SourceName, OrderNum )
	--( SELECT
	-- AsOfDate
	-- , SourceName
	-- , ROW_NUMBER() OVER(ORDER BY AsOfDate desc) as RowNumber
	-- FROM (
	-- SELECT DISTINCT(AsOfDate), '[dm01].[dbo].[SERV_Finastra_Monthly_Report]' as SourceName
	-- FROM [dm01].[dbo].[SERV_Finastra_Monthly_Report]
	-- UNION ALL
	-- select DISTINCT(AsOfDate), '[dm01].[dbo].[SERV_FICS_Monthly_Report]' as SourceName
	-- from [dm01].[dbo].[SERV_FICS_Monthly_Report]
	-- ) u
	--)
	DECLARE @MainDate DATETIME = '2023-10-31'
	-- Select AsOfDate
	-- from @FinDates
	-- where OrderNum = @MainOrderNum
	--)

------------------
--Find date for SLS Report needed
------------------
	DECLARE @SLSDate DATETIME = (
			SELECT DataAsofDate
			FROM [dm01].[dbo].[SERV_SLS_LastDateOfMonth]
				--(
				--SELECT DataAsOfDate
				--FROM 
				--	(
				--		SELECT DataAsOfDate, rn = ROW_NUMBER() OVER 
				--		( 
				--			PARTITION BY DATEDIFF(MONTH, '20000101', DataAsOfDate)
				--			ORDER BY DataAsOfDate DESC 
				--		) 
				--		FROM [dm01].[dbo].[SLS_OAKTREE_Standard_Daily]
				--	) AS x
				--WHERE x.rn = 1
				--) SERV_SLS_LastDateOfMonth
			WHERE YEAR(DataAsOfDate) = YEAR(@MainDate)
				AND MONTH(DataAsOfDate) = MONTH(@MainDate)
				AND DAY(DataAsOfDate) = DAY(@MainDate)
				--where YEAR(DataAsOfDate) = YEAR(DATEADD(d,-1,@MainDate)) and MONTH(DataAsOfDate) = MONTH(DATEADD(d,-1,@MainDate))
			);

------------------
--Get all data from Finastra Monthly Report for Report Date
------------------
	WITH f
	AS (
		SELECT *
		FROM [dm01].[dbo].[SERV_Finastra_Monthly_Report]
		WHERE cast(AsOfDate AS DATE) = cast(DATEADD(d, 1, @MainDate) AS DATE)
			--where AsOfDate = @MainDate
			AND StatusDesc <> 'Pending'
		)

------------------
--Get all DMI Loan Numbers for Loans in Finastra Snapshot from Finastra
------------------
		,tDMILoanID
	AS (
		SELECT *
		FROM (
			SELECT f.LoanID
				--, case when li.SBO_ServicerID is not NULL THEN li.SBO_ServicerID
				-- else af.Name
				-- end as Servicer
				,CASE 
					WHEN li.SBO_LoanID IS NOT NULL
						THEN li.SBO_LoanID
					ELSE sr.SRLoanNumber
					END AS DMILoanID
			--, s.CriticalWarning
			--, li.*, sr.*
			FROM f f
			--LEFT JOIN Status s on s.LoanID = p.LoanID
			LEFT JOIN finastra.dbo.LoanIdentity li ON li.LoanID = f.LoanID
			LEFT JOIN finastra.dbo.SRLoanData sr ON sr.LoanID = f.LoanID
				AND sr.ServicedByCode = '6'
			--LEFT JOIN AcquiredFrom af on sr.ServicedByCode = af.Code
			WHERE f.InvestorID = '04-001'
			) s
		WHERE s.DMILoanID IS NOT NULL
		)

------------------
--Get data from SLS Report for Report Date
------------------
		,SLSr
	AS (
		SELECT DataAsOfDate
			,ACCOUNT_NUMBER_PRIOR_SERVICER
			,DELQ_STATUS_MBA
			,BALANCE_PRINCIPAL_CURRENT
			,PAYMENT_DUE_DATE_NEXT
			,INTEREST_RATE_CURRENT
			,LOAN_SUB_TYPE
			,INTEREST_RATE_CHANGE_FIRST_DATE
			,PAYMENT_DUE_DATE_FIRST
			,MATURITY_DATE_CURRENT
			,LOAN_CLTV
			,INVESTOR_CODE
			,LOAN_WARNING_CODE_DESC
		FROM [dm01].[dbo].[SLS_OAKTREE_Standard_Daily]
		WHERE DataAsOfDate = @SLSDate and DELQ_STATUS_MBA <> 'Service Release'
		)

------------------
--Get data from DMI Reports (Active Loans, Paid Off Loans) for Report Date
------------------
		,DMIr
	AS (
		SELECT dmim.LoanNumber
			,dmim.PrincipalBalancePresent
			,dmim.DueDateEffective
			,dmim.InterestRate
			,dmim.PaymentNumber
			,NULL AS DatePaid
			,CASE
				WHEN dmiq.LOSS_MIT_STATUS_CODE='A' THEN 'FRB'
				ELSE NULL
				END AS LossMitStatus
			,dmim.AsOfDate
		FROM [dm01].[dbo].[SERV_DMI_Monthly_Report] dmim
		LEFT JOIN [dm01].[dbo].[SERV_DMI_Q05_LossMit_Monthly_Report] dmiq ON dmiq.LOAN_NUMBER = dmim.LoanNumber and dmiq.AsOfDate = dmim.AsOfDate
		WHERE YEAR(dmim.AsOfDate) = YEAR(@MainDate)
			AND MONTH(dmim.AsOfDate) = MONTH(@MainDate)
		--where YEAR(AsOfDate) = YEAR(DATEADD(d,-1,@MainDate)) and MONTH(AsOfDate) = MONTH(DATEADD(d,-1,@MainDate))
		
		UNION ALL
		
		SELECT LoanNumber
			,NULL AS PrincipalBalancePresent
			,NULL AS DueDateEffective
			,NULL AS InterestRate
			,NULL AS PaymentNumber
			,DatePaid
			,NULL AS LossMitStatus
			,AsOfDate
		FROM [dm01].[dbo].[SERV_DMI_PaidOff_Monthly_Report]
		WHERE AsOfDate <= EOMONTH(@MainDate)
			--where AsOfDate <= DATEADD(d,-1,@MainDate)
		)

------------------
--Build main query
------------------
	SELECT fitch.AsOfDate
		,convert(BIGINT, fitch.LoanID) AS LoanID
		,fitch.ProfileDescription
	------------------
	--Status
	--		-SERVICE TRANSFER-SOLD - if Loan is not serviced by SLS nor DMI, and is in Serv Rel status 
	------------------
		,CASE 
			WHEN (
					fitch.Servicer = 'AD'
					AND fitch.StatusDesc IN (
						'Serv Rel - w/EOY'
						,'Serv Rel - w/o EOY'
						)
					)
				THEN 'SERVICE TRANSFER-SOLD'
			ELSE fitch.StatusDesc
			END AS StatusDesc
		--, fitch.StatusDesc
		,fitch.ForbearanceStatus
		,fitch.PropertyState
		,fitch.InvestorName
		,fitch.InvestorClass
	------------------
	--Product Type
	--		-Agency (Investor Group - Fannie Mae or Freddie Mac)
	--		-Non-Agency Prime, Alt-A, Subprime (all others by CreditScore)
	------------------
		,CASE 
			WHEN fitch.InvestorClass = 'Fannie Mae'
				OR fitch.InvestorClass = 'Freddie Mac'
				THEN 'Agency'
			ELSE (
					CASE 
						WHEN fitch.CreditScore >= 740
							THEN 'Non-Agency Prime'
						WHEN fitch.CreditScore < 740
							AND fitch.CreditScore >= 670
							THEN 'Non-Agency Alt-A'
						WHEN fitch.CreditScore < 670
							THEN 'Non-Agency Subprime'
						ELSE '!OhNo!'
						END
					)
			END AS AgencyClass
		,CASE 
			WHEN (
					fitch.Servicer = 'AD'
					AND fitch.StatusDesc IN (
						'Serv Rel - w/EOY'
						,'Serv Rel - w/o EOY'
						)
					)
				THEN 'SOLD'
			ELSE fitch.Servicer
			END AS Servicer	
		,fitch.OriginalAmt
		,fitch.PrincipalBal
		,fitch.PrincipalBal / 1000 AS PrincipalBal_K
		,fitch.DueDate
		,fitch.InterestRate
		,fitch.ARMLoan
		,fitch.FrstRateChgDate
		,fitch.FirstDueDate
		,fitch.MaturityDate
		,fitch.NextPmtNum
		,fitch.FundingDate
		,fitch.OriginalLTV
		,fitch.CreditScore
	------------------
	--Credit Score class
	--		-Prime, Alt-A, Subprime (all others by CreditScore)
	------------------
		,CASE 
			WHEN fitch.CreditScore >= 740
				THEN 'Prime'
			WHEN fitch.CreditScore < 740
				AND fitch.CreditScore >= 670
				THEN 'Alt-A'
			WHEN fitch.CreditScore < 670
				THEN 'Subprime'
			ELSE '!OhNo!'
			END AS CSClass
		,fitch.Less_Than_24_Month_Seasoned
	------------------
	--Age
	--		-if DMI serviced then NextPmtNumber
	--      -else differenct between FirstDueDate and Report Date in months
	------------------
		,CASE 
			WHEN fitch.DMILoan = 1
				THEN fitch.NextPmtNum
			ELSE DATEDIFF(m, fitch.FirstDueDate, fitch.AsOfDate)
			END AS Age
		,DATEDIFF(m, fitch.AsOfDate, fitch.MaturityDate) AS MthsToMaturity
		,fitch.RMBS_Transaction_Date
	------------------
	--Delq Status
	--		-if SLS serviced then take SLS reported delq status
	--      -if Status=Pd-off Prepaid then Paid in Full
	------------------
		,CASE 
			WHEN fitch.SLSDelqStatus IS NOT NULL
				THEN fitch.SLSDelqStatus
			WHEN (
					fitch.Servicer = 'AD'
					AND fitch.StatusDesc IN (
						'Serv Rel - w/EOY'
						,'Serv Rel - w/o EOY'
						)
					)
				THEN 'SERVICE TRANSFER-SOLD'
			WHEN fitch.StatusDesc = 'Pd-off Prepaid'
				THEN 'Paid in Full'
			WHEN fitch.Warning = 'FCL'
				THEN 'Foreclosure'
			WHEN fitch.Warning = 'BK'
				THEN 'Bankruptcy'
			WHEN fitch.StatusDesc = 'DMI-Off'
				THEN 'DMI-Off'
			ELSE (
					CASE 
						WHEN DATEDIFF(m, fitch.DueDate, fitch.AsOfDate) < 1
							THEN 'Current'
						WHEN DATEDIFF(m, fitch.DueDate, fitch.AsOfDate) = 1
							THEN 'DQ 30'
						WHEN DATEDIFF(m, fitch.DueDate, fitch.AsOfDate) = 2
							THEN 'DQ 60'
						ELSE 'DQ 90'
						END
					)
			END AS DelqStatus
		,CASE 
			WHEN fitch.SLSDelqStatusCode IS NOT NULL
				THEN fitch.SLSDelqStatusCode
			WHEN (
					fitch.Servicer = 'AD'
					AND fitch.StatusDesc IN (
						'Serv Rel - w/EOY'
						,'Serv Rel - w/o EOY'
						)
					)
				THEN 10
			WHEN fitch.StatusDesc = 'Pd-off Prepaid'
				THEN 11
			WHEN fitch.Warning = 'FCL'
				THEN 4
			WHEN fitch.Warning = 'BK'
				THEN 5
			WHEN fitch.StatusDesc = 'DMI-Off'
				THEN -1
			ELSE (
					CASE 
						WHEN DATEDIFF(m, fitch.DueDate, fitch.AsOfDate) < 1
							THEN 0
						WHEN DATEDIFF(m, fitch.DueDate, fitch.AsOfDate) = 1
							THEN 1
						WHEN DATEDIFF(m, fitch.DueDate, fitch.AsOfDate) = 2
							THEN 2
						ELSE 3
						END
					)
			END AS DelqStatusCode
	FROM (
		SELECT @MainDate AS AsOfDate
			--DATEADD(d, -1, @MainDate) as AsOfDate
			,f.LoanID
			,f.ProfileDescription
		------------------
		--Status
		--		-DMI-Off (shouldn't appear) - when DMI Loan Number found, Loan is not found in DMI reports, Finastra shows loans as transferred to DMI
		--		-Pd-Off Prepais - if Loan is serviced by DMI and has DatePaid; if Loan is serviced by SLS and Paid in Full; if Loan is serviced by AD - as in Finastra
		--      -Other finastra statuses
		------------------
			,CASE 
				WHEN (
						tDMI.DMILoanID IS NOT NULL
						AND DMIr.LoanNumber IS NULL
						AND f.StatusDesc = 'Serv Rel - w/o EOY'
						)
					THEN 'DMI-Off'
				WHEN (
						tDMI.DMILoanID IS NOT NULL
						AND DMIr.LoanNumber IS NOT NULL
						AND DMIr.DatePaid IS NOT NULL
						)
					THEN 'Pd-off Prepaid'
				WHEN (
						tDMI.DMILoanID IS NOT NULL
						AND DMIr.LoanNumber IS NOT NULL
						AND DMIr.DatePaid IS NULL
						)
					THEN 'DMI - Active'
				WHEN SLSr.ACCOUNT_NUMBER_PRIOR_SERVICER IS NOT NULL
					AND SLSr.DELQ_STATUS_MBA <> 'Paid in Full'
					THEN 'SLS - Active'
				WHEN SLSr.ACCOUNT_NUMBER_PRIOR_SERVICER IS NOT NULL
					AND SLSr.DELQ_STATUS_MBA = 'Paid in Full'
					THEN 'Pd-off Prepaid'
				ELSE f.StatusDesc
				END AS StatusDesc
			,f.CriticalWarning
			,f.Legal
			,f.Warning
			,CASE 
				WHEN tDMI.DMILoanID IS NOT NULL
						AND DMIr.LoanNumber IS NOT NULL
						AND DMIr.LossMitStatus = 'FRB'
					THEN 'FRB'
				WHEN SLSr.ACCOUNT_NUMBER_PRIOR_SERVICER IS NOT NULL
						AND SLSr.LOAN_WARNING_CODE_DESC like '%Forbearance%'
					THEN 'FRB'
				WHEN f.Warning = 'FRB'
					THEN 'FRB'
				ELSE NULL
				END AS ForbearanceStatus
			,f.PropertyState
			,f.InvestorName
		------------------
		--Servicer
		--		-has DMI ID in Finastra and is in DMI Reports - DMI
		--      -in SLS Report - SLS
		--      -otherwise AD (but some loans are SERVICE TRANSFER-SOLD)
		------------------
			,CASE 
				WHEN tDMI.LoanID IS NOT NULL
						AND DMIr.LoanNumber IS NOT NULL
					THEN 'DMI'
				WHEN SLSr.ACCOUNT_NUMBER_PRIOR_SERVICER IS NOT NULL
					THEN 'SLS'
				ELSE 'AD'
				END AS Servicer
		------------------
		--DMILoan
		--		-has DMI ID in Finastra and is in DMI Reports
		------------------
			,CASE 
				WHEN  tDMI.DMILoanID IS NOT NULL
						AND DMIr.LoanNumber IS NOT NULL
					THEN 1
				ELSE 0
				END AS DMILoan
			--,CASE 
			--	WHEN SLSr.ACCOUNT_NUMBER_PRIOR_SERVICER IS NOT NULL
			--		THEN 1
			--	ELSE 0
			--	END AS SLSLoan
		------------------
		--Investor Group - Classification
		--		-Fannie Mae
		--		-Freddie Mac
		--		-Non-Agency RMBS (securitized loans - IF and JP securitizations and SLS securitized loans)
		--		-Others
		------------------
			,CASE 
				WHEN f.InvestorID = '04-001'
					OR tDMI.LoanID IS NOT NULL
					THEN 'Fannie Mae'
				WHEN f.InvestorID = '06-001'
					THEN 'Freddie Mac'
				WHEN (
						f.InvestorID LIKE '%05-0%' OR f.InvestorID = '05-15'
						AND f.InvestorID <> '05-000'
						AND f.InvestorID <> '05-004'
						)
					THEN 'Non-Agency RMBS'
				WHEN (
						f.InvestorID LIKE '%03-0%'
						AND f.InvestorID <> '03-001'
						)
					THEN 'Non-Agency RMBS'
				WHEN SLSi.Securitized = 1
					THEN 'Non-Agency RMBS'
				ELSE 'Others'
				END AS InvestorClass
			,f.OriginalAmt
		------------------
		--Current Principal Balance - from DMI, SLS and Finastra
		------------------
			,CASE 
				WHEN tDMI.DMILoanID IS NOT NULL
						AND DMIr.LoanNumber IS NOT NULL
					THEN DMIr.PrincipalBalancePresent
				WHEN SLSr.ACCOUNT_NUMBER_PRIOR_SERVICER IS NOT NULL
					THEN SLSr.BALANCE_PRINCIPAL_CURRENT
				ELSE f.PrincipalBal
				END AS PrincipalBal
		------------------
		--DueDate - from DMI, SLS and Finastra
		------------------
			,CASE 
				WHEN tDMI.DMILoanID IS NOT NULL
						AND DMIr.LoanNumber IS NOT NULL
					THEN DMIr.DueDateEffective
				WHEN SLSr.ACCOUNT_NUMBER_PRIOR_SERVICER IS NOT NULL
					THEN SLSr.PAYMENT_DUE_DATE_NEXT
				ELSE f.DueDate
				END AS DueDate
		------------------
		--InterestRate - from DMI, SLS and Finastra
		------------------
			,CASE 
				WHEN tDMI.DMILoanID IS NOT NULL
						AND DMIr.LoanNumber IS NOT NULL
					THEN DMIr.InterestRate / 100
				WHEN SLSr.ACCOUNT_NUMBER_PRIOR_SERVICER IS NOT NULL
					THEN SLSr.INTEREST_RATE_CURRENT / 100
				ELSE f.InterestRate
				END AS InterestRate
		------------------
		--ARM Loan - from SLS and Finastra
		------------------
			,CASE 
				WHEN SLSr.ACCOUNT_NUMBER_PRIOR_SERVICER IS NOT NULL
					THEN (
							CASE 
								WHEN SLSr.LOAN_SUB_TYPE = 'ARM (Adjustable Rate Mortgage)'
									THEN 1
								ELSE 0
								END
							)
				ELSE f.ARMLoan
				END AS ARMLoan
		------------------
		--ARM FrstRateChgDate - from SLS and Finastra
		------------------
			,CASE 
				WHEN SLSr.ACCOUNT_NUMBER_PRIOR_SERVICER IS NOT NULL
					THEN SLSr.INTEREST_RATE_CHANGE_FIRST_DATE
				ELSE f.FrstRateChgDate
				END AS FrstRateChgDate
		------------------
		--First DueDate - from SLS and Finastra
		------------------
			,CASE 
				WHEN SLSr.ACCOUNT_NUMBER_PRIOR_SERVICER IS NOT NULL
					THEN SLSr.PAYMENT_DUE_DATE_FIRST
				ELSE f.FirstDueDate
				END AS FirstDueDate
		------------------
		--Maturity Date - from SLS and Finastra
		------------------
			,CASE 
				WHEN SLSr.ACCOUNT_NUMBER_PRIOR_SERVICER IS NOT NULL
					THEN SLSr.MATURITY_DATE_CURRENT
				ELSE f.MaturityDate
				END AS MaturityDate
		------------------
		--Next Payment Number - from DMI, SLS and Finastra
		------------------
			,CASE 
				WHEN tDMI.DMILoanID IS NOT NULL
						AND DMIr.LoanNumber IS NOT NULL
					THEN DMIr.PaymentNumber
				WHEN SLSr.ACCOUNT_NUMBER_PRIOR_SERVICER IS NOT NULL
					THEN NULL
				ELSE f.NextPmtNum
				END AS NextPmtNum
			,f.FundingDate
		------------------
		--LTV - from SLS and Finastra
		------------------
			,CASE 
				WHEN SLSr.ACCOUNT_NUMBER_PRIOR_SERVICER IS NOT NULL
					THEN SLSr.LOAN_CLTV / 100
				ELSE f.OriginalLTV
				END AS OriginalLTV
		------------------
		--CreditScore
		------------------
			,CASE 
				WHEN cs.Score_Fitch20221231 IS NOT NULL
					THEN convert(VARCHAR, cs.Score_Fitch20221231)
				WHEN cs.Score_Fitch20221231 IS NULL
					AND cs.Score IS NOT NULL
					THEN convert(VARCHAR, cs.Score)
				WHEN cs.Score_Fitch20221231 IS NULL
					AND cs.Score IS NULL
					AND f.CreditScore IS NOT NULL
					AND f.CreditScore <> 0
					AND f.CreditScore <> 1
					THEN convert(VARCHAR, f.CreditScore)
				ELSE '!OhNo!'
				END AS CreditScore
			,SLSr.DELQ_STATUS_MBA AS SLSDelqStatus
			,CASE 
				WHEN SLSr.DELQ_STATUS_MBA = 'Current'
					THEN 0
				WHEN SLSr.DELQ_STATUS_MBA = 'DQ 30'
					THEN 1
				WHEN SLSr.DELQ_STATUS_MBA = 'DQ 60'
					THEN 2
				WHEN SLSr.DELQ_STATUS_MBA = 'DQ 90'
					THEN 3				
				WHEN SLSr.DELQ_STATUS_MBA = 'Foreclosure'
					THEN 4
				WHEN SLSr.DELQ_STATUS_MBA = 'Bankruptcy'
					THEN 5
				WHEN SLSr.DELQ_STATUS_MBA = 'Paid in Full'
					THEN 11	
				END AS SLSDelqStatusCode
		------------------
		--Calculation of Months Seasoned
		------------------
			,CASE 
				WHEN DATEDIFF(m, FundingDate, @MainDate) <= 24
					THEN 1
						--case when DATEDIFF(m, FundingDate, DATEADD(d, -1, @MainDate)) <= 24 THEN 1
				ELSE 0
				END AS Less_Than_24_Month_Seasoned
			,ifdate.ClosingDate AS RMBS_Transaction_Date
		FROM f f
		LEFT JOIN tDMILoanID tDMI ON tDMI.LoanID = f.LoanID
		--LEFT JOIN [dm01].[dbo].[SLS_OAKTREE_Standard_Daily] SLSr on SLSr.ACCOUNT_NUMBER_PRIOR_SERVICER = convert(bigint, f.LoanID) and SLSr.DataAsOfDate = @SLSDate
		LEFT JOIN SLSr SLSr ON SLSr.ACCOUNT_NUMBER_PRIOR_SERVICER = convert(BIGINT, f.LoanID)
		LEFT JOIN [dm01].[dbo].[SLS_Investor] SLSi ON SLSr.INVESTOR_CODE = SLSi.InvCode
		--LEFT JOIN [dm01].[dbo].[SERV_DMI_Monthly_Report] DMIr on DMIr.LoanNumber = tDMI.DMILoanID and YEAR(DMIr.AsOfDate) = YEAR(DATEADD(d,-1,@MainDate)) and MONTH(DMIr.AsOfDate) = MONTH(DATEADD(d,-1,@MainDate))
		LEFT JOIN DMIr DMIr ON DMIr.LoanNumber = tDMI.DMILoanID
		LEFT JOIN [dm01].[dbo].[SERV_Fitch_CreditScore] cs ON cs.LoanID = f.LoanID
		LEFT JOIN [dm01].[dbo].[IF_SecuritizationLoans] ifloans ON ifloans.Loan_Number = convert(BIGINT, f.LoanID)
		LEFT JOIN [dm01].[dbo].[IF_SecuritizationDate] ifdate ON ifloans.InvestorID = ifdate.InvestorID
		) fitch
