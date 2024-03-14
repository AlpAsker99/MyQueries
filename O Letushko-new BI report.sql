
-- O.Letushko Branch Report

/*
|||			  Last Change Date: 02/20/2024			 |||
||| Creator And Responsible Person: Aleskerov Nurlan ||| 
*/

WITH 
	branch_ass--assigned LO's
	AS
	(
	SELECT 
	
		 loanrecordid
		 ,[Loan #]
		,[Contact Name]

	FROM dm01.dbo.loan_contacts

	WHERE [Contact Category ID] = 121		--LO
	AND [User ID] in (2898,22621,16273)		--Olga, Xavier, Augustina


	UNION


	SELECT
	
		 loanrecordid
		 ,[Loan #]
		,[Contact Name]

	FROM dm01.dbo.loan_contacts

	WHERE [Contact Category ID] = 69		--LO Branch Support
	AND [User ID] in (2898,22621,16273)		--Olga, Xavier, Augustina
	)


--MAIN SELECT------------------------------------

SELECT

	 IIF(YEAR(lpc.submissiondate)=1800, NULL, lpc.submissiondate) 
								AS	[Submission Date]
	,borr.							[Borrower Name]
	,lm.loanid					AS	[Loan #]
	,IIF(YEAR(lpc.dateclosingfunded)=1800, NULL, lpc.dateclosingfunded)
								AS	[Actual Closing Date]
	,IIF(YEAR(lm.estimatedclosingdate)=1800, NULL, lm.estimatedclosingdate)
								AS	[Estimated Closing Date]
	,ass.[Contact Name]			AS	[Originator]
	,lm.loanamount				AS	[Loan Amount]
	,sdt.doctypedesc			AS	[Product]
	,IIF(ppt.purposetypealias like'Purch%', 'Purchase', 'Refi - '+refipurpose) 		
								AS	[Loan Purpose]
	,sls.statusdescription		AS	[Loan Status]

FROM loan_main								lm

JOIN branch_ass								ass
	ON lm.loanrecordid=ass.loanrecordid

LEFT JOIN loan_postclosing					lpc
	ON lpc.loanrecordid=lm.loanrecordid

LEFT JOIN product_purposetype				ppt
    ON ppt.purposetypeid = lm.purposetypeid

LEFT JOIN loan_automatedunderwriting		lau
	ON lau.loanrecordid=lm.loanrecordid

LEFT JOIN setups_doctype					sdt
	ON sdt.doctypeid=lau.documenttype

LEFT JOIN dm01.dbo.view_integra_borrowers	borr
	ON borr.loanrecordid=ass.loanrecordid
	AND borr.[Borrower Sorter]=1

LEFT JOIN setups_loanstatus					sls
	ON sls.statusid=lm.statusid

WHERE lm.loanrecordid NOT IN (select
									*
									from dm01.dbo.integra_test_loans)
AND YEAR(lpc.submissiondate)!=1800
AND (
	CASE
		WHEN YEAR(lpc.dateclosingfunded)=1800 
			 AND DATEDIFF(YEAR, lpc.submissiondate, GETDATE())>0
		THEN '0'
		ELSE '1'
	  END
	  )='1'

