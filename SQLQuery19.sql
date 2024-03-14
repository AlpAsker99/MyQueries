---------------------------------------#5 - Exception

SELECT top 7
	--lm.loanid AS [Loan #]
	--, CASE 
		--WHEN clm.adm_IsLoanConsideredAsException = 1
		--	THEN 'Y'
		--ELSE 'N'
		--END AS [Exception Flag]
	dm01.dbo.MDY_EXTRACT ([Exc_comm_tbl].Exc_comm)
		AS [Exception Text]
		,[Exc_comm_tbl].Exc_comm
		
FROM custom_loanmain clm
LEFT JOIN loan_main lm
	ON lm.lenderdatabaseid=clm.lenderdatabaseid
	AND lm.loanrecordid=clm.loanrecordid
LEFT JOIN (
	select recordid
		, lenderdatabaseid
		, STRING_AGG(cast(vt_vartextid as VARCHAR(MAX)), ' | ') as [Exc_comm]
	from integra.dbo.loan_comments Results
	where vt_vartextid like '%except%'
	GROUP BY recordid, lenderdatabaseid
    ) [Exc_comm_tbl]
	ON [Exc_comm_tbl].recordid = lm.loanrecordid
		AND [Exc_comm_tbl].lenderdatabaseid = lm.lenderdatabaseid
WHERE lm.loanrecordid NOT IN (
		SELECT loanrecordid
		FROM dm01.dbo.integra_test_loans
		)
		and [Exc_comm_tbl].Exc_comm is not null
		and [Exc_comm_tbl].Exc_comm not like '%[%]%'
		and [Exc_comm_tbl].Exc_comm not like '%,7%'