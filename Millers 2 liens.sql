SELECT
	 
	 lm.loanid											[Loan #]
	,lpc.lienposition									[Lien Position]
	,													[LO Company Key]
	,lc.[Contact Name]								AS	[AE Name]
	,Case 
		WHEN lc.[Borrower #2 Name] is null
		THEN lc.[Borrower #1 Name] 
		ELSE lc.[Borrower #1 Name]+', '+lc.[Borrower #2 Name] 
		END AS											[Borrower(s)]

FROM loan_main											lm

LEFT JOIN loan_postclosing								lpc
	ON lpc.loanrecordid = lm.loanrecordid

LEFT JOIN dm01.dbo.loan_contacts lc
	ON lc.[Loan #]=lm.loanid
	AND lc.[Contact Category ID]=99

WHERE lpc.lienposition = 2
AND lm.loanid not in (SELECT *
        FROM dm01.dbo.integra_test_loans)
