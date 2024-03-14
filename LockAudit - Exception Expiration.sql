	select * from [INFORMATION_SCHEMA].[COLUMNS]
	where TABLE_NAME like '%loan_psadjustments%'
	and COLUMN_NAME like '%description%'
	and

SELECT 
	lm.loanid																[Loan #]
	--, CASE 
	--	WHEN adj.adj like '*** Placeholder%' 
	--	THEN '***unknown comment***'
	--	ELSE adj.adj
	--	END AS																[Adj Comment]
	, CASE 
		--WHEN lm.loanlocked = 0
		WHEN adj.adj like 'The exception due date is%'
		AND datediff(day,(cast((substring(adj.adj, len(adj.adj)-10, len(adj.adj))) as date)), (cast(left(getdate(), 11) as date)))>=14
		THEN 'Expired'
		--WHEN lm.loanlocked = 0
		WHEN adj.adj like 'The exception due date is%'
		AND datediff(day,(cast((substring(adj.adj, len(adj.adj)-10, len(adj.adj))) as date)), (cast(left(getdate(), 11) as date)))<14
		THEN cast(datediff(day,(cast((substring(adj.adj, len(adj.adj)-10, len(adj.adj))) as date)), (cast(left(getdate(), 11) as date))) as varchar)
		END AS																[Days Left Until Expiration]
FROM loan_main lm
--LEFT JOIN loan_psadjustments lpsa
--	ON lm.loanrecordid=lpsa.loanrecordid 
--	AND lpsa.lenderdatabaseid=lm.lenderdatabaseid
INNER JOIN dm01.[dbo].[adj_test] adj
	ON lm.loanid=adj.id
WHERE lm.loanrecordid not in (SELECT *
        FROM dm01.dbo.integra_test_loans)
AND lm.loanid != 'Not Assigned'
-----====================================


create table ##attempt (a varchar (100))
insert into ##attempt values ('must be locked before 10/04'), ('must be locked before 10/05 '),('must be locked before 10/ 06'),
('must be locked before 10 /02'),('must be locked before 10 / 03'),('must be locked before 10.04')
	

SELECT 
	case 
	when right(a.a, 1) not like '%[^0-9]%'
	then 'Check The Spelling (Space?)'
	when right(a.a, 2) not  between 0 and 9
	then 'Check The Spelling (Space?)'
	when right(a.a, 3) !='/'
	then 'Check The Spelling (Space?)'

	when right(a.a, 4)  not between 0 and 9
	then 'Check The Spelling (Space?)'
	when right(a.a, 5)  not between 0 and 9
	then 'Check The Spelling (Space?)'


	else
	 cast (datediff (day, (cast(right(a.a, 6)+'/2023' as date)), getdate()) as varchar (100))

	end as [tab]




FROM ##attempt a
where a.a= 'must be locked before 10/04'

select * from ##attempt 

--------================--------================--------================--------================--------================--------================

--Creating Functions