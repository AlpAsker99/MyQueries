----------#7 Exception-Lock Expiration Check
use integra
SELECT 
	 lm.loanrecordid
	,lm.loanid 
	,commenttext
	,CASE 
		WHEN [Exc_comm_tbl].Exc_comm like '%must%be%locked%'
		THEN [Exc_comm_tbl].Exc_comm
		else null
		end as [date]
		--,lpsa.description
		--,[Exc_comm_tbl].Exc_comm
		--AS [Exception Text]
FROM loan_main lm
LEFT JOIN loan_psadjustments lpsa
	ON lm.loanrecordid=lpsa.loanrecordid 
LEFT JOIN (
	select recordid
		, lenderdatabaseid
		, STRING_AGG(cast(vt_vartextid as VARCHAR(MAX)), ' | ') as [Exc_comm]
	from integra.dbo.loan_comments Results

	GROUP BY recordid, lenderdatabaseid
    ) [Exc_comm_tbl]
	ON [Exc_comm_tbl].recordid = lm.loanrecordid
		AND [Exc_comm_tbl].lenderdatabaseid = lm.lenderdatabaseid
LEFT JOIN loan_conditions lc
on lc.loanrecordid=lm.loanrecordid
where lm.loanid='1055563'


		select * from [INFORMATION_SCHEMA].[COLUMNS]
		where [COLUMN_NAME] like '%comment%'

		select * from loan_comments where recordid='53558'



	