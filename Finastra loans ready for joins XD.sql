USE [dm01]
GO

/****** Object:  StoredProcedure [dbo].[usp_INS_SERV_FinMonthlyUpd]    Script Date: 10/12/2023 6:41:15 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE     proc [dbo].[usp_INS_SERV_FinMonthlyUpd]
as begin 

;with precalcPayoffHistory as (
	select 
	DENSE_RANK () over (partition by loanid order by historycounter desc) as rank,
	* 
	from finastra.dbo.History 
	where TransactionCode = 110
)

, PayoffHistory as (
	select LoanID,
	TransactionDate
	from precalcPayoffHistory 
	where rank=1
)

, CSD as (
	select CSAutoID, LoanID, AssmRecCounter, BorrowerID, Score, ScoreDesc
	from finastra.dbo.CreditScoreDetail
	where CSAutoID in (
		select max(CSAutoID)
		from finastra.dbo.CreditScoreDetail
		group by LoanID, BorrowerID
		)
)

--INSERT INTO dm01.dbo.SERV_Finastra_Monthly_Report
select * from  [dbo].[SERV_Main] order by AsOfDate desc

select * from dm01.dbo.SERV_Finastra_Monthly_Report order by AsOfDate desc

SELECT
	GETUTCDATE() AT TIME ZONE 'UTC' AT TIME ZONE 'Eastern Standard Time',
	Loan.LoanID, 
	--Loan.LoanProfile,
	LoanProfile.ProfileDescription, 
	--Status.PrimStat,
	StatusDescription.Description as StatusDesc,
	Status.CriticalWarning, 
	Status.Legal, 
	Status.Warning, 
	Property.State AS PrState, 
	Investor.InvestorID, 
	Investor.Name,
	Loan.OriginalAmt, 
	Loan.PrincipalBal, 
	Loan.DueDate, 
	Loan.InterestRate, 
	Loan.ARMLoan,
	Loan.FirstDueDate, 
	Loan.MaturityDate, 
	Loan.NextPmtNum, 
	Loan.FundingDate, 
	Property.OriginalLTV, 
	ARM.FrstRateChgDate, 
	CreditScoreDetail_1.Score as CreditScore, 
	CreditScoreDetail_2.Score as SecBor_CreditScore, 
	Delinquent.Collector,
	PayoffHistory.TransactionDate as PayoffTransactionDate
FROM

finastra.dbo.Loan Loan
INNER JOIN finastra.dbo.Status Status ON Loan.LoanID = Status.LoanID
INNER JOIN finastra.dbo.Delinquent Delinquent ON Loan.LoanID = Delinquent.LoanID
LEFT JOIN finastra.dbo.Property Property ON Loan.LoanID = Property.LoanID
LEFT JOIN finastra.dbo.LoanProfile LoanProfile ON Loan.LoanProfile = LoanProfile.LoanProfile
LEFT JOIN finastra.dbo.SystemTypes StatusDescription ON Status.PrimStat = StatusDescription.Code AND StatusDescription.FieldName = 'PrimStat'
LEFT JOIN finastra.dbo.Participation Participation ON Loan.LoanID = Participation.LoanID and Participation.PrimaryInvestorFlag = 1 and Participation.PendingFlag = 0
LEFT JOIN finastra.dbo.Investor Investor ON Participation.InvestorID = Investor.InvestorID
LEFT JOIN finastra.dbo.ARM ARM ON Loan.LoanID = ARM.LoanID
LEFT JOIN CSD CreditScoreDetail_1 ON (Loan.LoanID = CreditScoreDetail_1.LoanID) AND (CreditScoreDetail_1.BorrowerID = 1) and (CreditScoreDetail_1.AssmRecCounter = Loan.AssmRecCounter)
LEFT JOIN CSD CreditScoreDetail_2 ON (Loan.LoanID = CreditScoreDetail_2.LoanID) AND (CreditScoreDetail_2.BorrowerID = 2) and (CreditScoreDetail_2.AssmRecCounter = Loan.AssmRecCounter)
LEFT JOIN PayoffHistory PayoffHistory on Loan.LoanID = PayoffHistory.LoanID

end
GO


