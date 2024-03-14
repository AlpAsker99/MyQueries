-----------------------------------------------
with pivot_credit_scores AS (
	select *
	from 
	(
		SELECT
			score
			, convert(varchar, customerid) + '_' + repositorysource as id_rep
			, requestid
		from credit_scores
		--where requestid = '202111080000001'
	) PivotData
	PIVOT (max(score) FOR id_rep IN ([0_TransUnion], [0_Experian], [0_Equifax], [1_TransUnion], [1_Experian], [1_Equifax], [2_TransUnion], [2_Experian], [2_Equifax])) as P
)
-------------------------------------------------

select lm.loanid
, lpc.submissiondate
, lpc.dateclosingfunded
--, l.LoanID
--, sls.statusdescription
, lm.creditscore as LoanCreditScore
, cmn.firstname as CMNFirstName
, cmn.lastname as CMNLastName
, cmn.race
, cmn.citizenship
, REPLACE(cmn.ssnumber,'-','')
, ccmn.requestid
--, cmn.citizenship as CMNCitizenship
, cmn.creditscore as CMNCreditScore
, pcs.[1_Equifax]
, pcs.[1_Experian]
, pcs.[1_TransUnion]
--, cmn.equifaxscore
--, cmn.experianscore
--, cmn.transunionscore
--, cmn.preferedlanguageother
--, cmn.preferedlanguagetype
, cmn_cob.firstname as CobFirstName
, cmn_cob.lastname as CobLastName
, REPLACE(cmn_cob.ssnumber,'-','')
--, cmn_cob.citizenship as CobCitizenship
, cmn_cob.creditscore as CobCreditScore
, pcs.[2_Equifax]
, pcs.[2_Experian]
, pcs.[2_TransUnion]
, cmn_sec.firstname as SecFirstName
, cmn_sec.lastname as SecLastName
, REPLACE(cmn_sec.ssnumber,'-','')
--, cmn_sec.citizenship as SecCitizenship
, cmn_sec.creditscore as SecCreditScore
, pcs.[0_Equifax]
, pcs.[0_Experian]
, pcs.[0_TransUnion]
from loan_main lm
left join loan_postclosing lpc on lm.loanrecordid=lpc.loanrecordid and lpc.lenderdatabaseid=lm.lenderdatabaseid
LEFT JOIN customer_group cg 
  ON lm.customergroupid=cg.customergroupid 
  AND lm.lenderdatabaseid=cg.lenderdatabaseid 
  AND cg.customernumber=1 AND cg.primarycustomer='Y'
LEFT JOIN customer_main cmn 
  ON cg.customerrecordid=cmn.customerrecordid 
  AND cg.lenderdatabaseid=cmn.lenderdatabaseid
LEFT JOIN customer_main cmn_cob 
  ON cg.joinedcustomerid=cmn_cob.customerrecordid 
  AND cg.lenderdatabaseid=cmn_cob.lenderdatabaseid
LEFT JOIN customer_group cg_sec 
  ON lm.customergroupid=cg_sec.customergroupid 
  AND lm.lenderdatabaseid=cg_sec.lenderdatabaseid 
  AND cg_sec.primarycustomer='N' AND cg_sec.customernumber=
	CASE WHEN cg.joinedcustomerid=0 OR cg.joinedcustomerid is NULL THEN 2 --main borrower doesn't have co-borrower
		WHEN cg.joinedcustomerid<>0 THEN 3 --main borrower has co-borrower
		END
LEFT JOIN customer_main cmn_sec 
  ON cg_sec.customerrecordid=cmn_sec.customerrecordid 
  AND cg_sec.lenderdatabaseid=cmn_sec.lenderdatabaseid
INNER JOIN finastra.dbo.Loan l ON RIGHT(l.LoanID, 7) = lm.loanid AND LEFT(l.LoanID, 3) = '000'
left join setups_loanstatus sls on lm.statusid=sls.statusid
left join credit_customer ccmn ON REPLACE(cmn.ssnumber,'-','') = ccmn.socsecnumber and cmn.lastname = ccmn.lastname and cmn.firstname = ccmn.firstname and ccmn.requestid = (
	select max(requestid)
	from credit_customer
	where socsecnumber = ccmn.socsecnumber and lastname = ccmn.lastname and firstname = ccmn.firstname
	)
left join pivot_credit_scores pcs on pcs.requestid = ccmn.requestid
--left join credit_scores cscmn_transunion ON ccmn.requestid = cscmn.requestid and cscmn.repositorysource = 'TransUnion'
--left join credit_scores cscmn_equifax ON ccmn.requestid = cscmn.requestid and cscmn.repositorysource = 'Equifax'
--left join credit_scores cscmn_experian ON ccmn.requestid = cscmn.requestid and cscmn.repositorysource = 'Experian'
where lm.loanrecordid not in (
  select * from dm01.dbo.integra_test_loans
  )
and lm.loanid in (
'1045086'
,'1050543'
,'1051431'
,'1051660'
,'1051713'
,'1051921'
,'1052518'
,'1052577'
,'1052586'
,'1052704'
,'1052988'
,'1053257'
,'1053318'
,'1053563'
,'1053618'
,'1053651'
,'1053667'
,'1053807'
,'1054156'
,'1054386'
,'1054513'
,'1054528'
,'1054549'
,'1054769'
,'1054806'
,'1055595'
)
order by lm.loanid 

---------------------------------------------------------------------



select lm.loanid
--, cmn.citizenship
, case when cmn.citizenship = 'National' then 650
	when cmn.citizenship = 'Citizen' then 700
	else NULL
	end as CreditScore
from loan_main lm
LEFT JOIN customer_group cg 
  ON lm.customergroupid=cg.customergroupid 
  AND lm.lenderdatabaseid=cg.lenderdatabaseid 
  AND cg.customernumber=1 AND cg.primarycustomer='Y'
LEFT JOIN customer_main cmn 
  ON cg.customerrecordid=cmn.customerrecordid 
  AND cg.lenderdatabaseid=cmn.lenderdatabaseid
where lm.loanrecordid not in (
  select * from dm01.dbo.integra_test_loans
  )
and lm.loanid in (
'1045086'
,'1050543'
,'1051431'
,'1051660'
,'1051713'
,'1051921'
,'1052518'
,'1052577'
,'1052586'
,'1052704'
,'1052988'
,'1053257'
,'1053318'
,'1053563'
,'1053618'
,'1053651'
,'1053667'
,'1053807'
,'1054156'
,'1054386'
,'1054513'
,'1054528'
,'1054549'
,'1054769'
,'1054806'
,'1055595'
)
order by lm.loanid

select * from 
dm01.[dbo].[SERV_Fitch_CreditScore]

insert into dm01.[dbo].[SERV_Fitch_CreditScore] (LoanID, Score)
select lm.loanid as LoanID 
--, cmn.citizenship
, case when cmn.citizenship = 'National' then 650
	when cmn.citizenship = 'Citizen' then 700
	when cmn.citizenship = 'Nonresident' then 700
	when cmn.citizenship = 'Resident' then 700
	else NULL
	end as Score
from loan_main lm
LEFT JOIN customer_group cg 
  ON lm.customergroupid=cg.customergroupid 
  AND lm.lenderdatabaseid=cg.lenderdatabaseid 
  AND cg.customernumber=1 AND cg.primarycustomer='Y'
LEFT JOIN customer_main cmn 
  ON cg.customerrecordid=cmn.customerrecordid 
  AND cg.lenderdatabaseid=cmn.lenderdatabaseid
where lm.loanrecordid not in (
  select * from dm01.dbo.integra_test_loans
  )
and lm.loanid in 
--where loanid in 
 (
'1045086'
,'1050543'
,'1051431'
,'1051660'
,'1051713'
,'1051921'
,'1052518'
,'1052577'
,'1052586'
,'1052704'
,'1052988'
,'1053257'
,'1053318'
,'1053563'
,'1053618'
,'1053651'
,'1053667'
,'1053807'
,'1054156'
,'1054386'
,'1054513'
,'1054528'
,'1054549'
,'1054769'
,'1054806'
,'1055595'
)




select top 1 *
from customer_main

--and sls.statusdescription in ('Started', 'Suspended Investor Conditions')
--and lm.creditscore <> cmn.creditscore
and lm.loanid = '1040859'
order by lm.LoanID--REPLACE(cmn.ssnumber,'-','')--ccmn.requestid--lm.LoanID

select DISTINCT(sls.statusdescription)
from loan_main lm
INNER JOIN finastra.dbo.Loan l ON RIGHT(l.LoanID, 7) = lm.loanid AND LEFT(l.LoanID, 3) = '000'
left join setups_loanstatus sls on lm.statusid=sls.statusid 

select Loan_ID,
Page_1003_Borrower_Citizenship,
Page_1003_Borrower_Credit_Score,
Page_1003_Borrower_2_Citizenship,
Page_1003_Borrower_2_Credit_Score
from dm01.dbo.OC_2

select FirstMiddleName, LastName, count(*)
from Borrower
group by FirstMiddleName, LastName
having count(*) > 1

select *
from Borrower

select *
from Borrower
where FirstMiddleName='Amrou' and LastName='Fudl'


select *--COUNT(DISTINCT(socsecnumber))
from credit_customer cc
left join credit_scores cs on cs.requestid = cc.requestid 
where cc.socsecnumber = '611403826'

select top 1 *
from customer_main

select *
from credit_scores
where requestid = 202108060000001




WITH PivotData AS
(
    SELECT
        score
        , convert(varchar, customerid) + '_' + repositorysource as id_rep
		, requestid
    from credit_scores
	--where requestid = '202301060000067'
)

select *
from 
(
    SELECT
        score
        , convert(varchar, customerid) + '_' + repositorysource as id_rep
		, requestid
    from credit_scores
	--where requestid = '202301060000067'
) PivotData
PIVOT (max(score) FOR id_rep IN ([0_TransUnion], [0_Experian], [0_Equifax], [1_TransUnion], [1_Experian], [1_Equifax], [2_TransUnion], [2_Experian], [2_Equifax])) as P



(
SELECT
    score
	, id_rep
FROM
PivotData) toPivot
PIVOT (max(score) FOR id_rep IN ([0_TransUnion], [0_Experian], [0_Equifax], [1_TransUnion], [1_Experian], [1_Equifax], [2_TransUnion], [2_Experian], [2_Equifax])) as P

SELECT score, id_rep
FROM
(
    SELECT
        cs.score, convert(varchar, cs.customerid) + '_' + cs.repositorysource as id_rep
    from credit_scores cs
	where cs.requestid = '202301060000067'
) as toPivot
PIVOT (max(score) FOR id_rep IN ([0_TransUnion], [0_Experian], [0_Equifax], [1_TransUnion], [1_Experian], [1_Equifax], [2_TransUnion], [2_Experian], [2_Equifax])) as P













[0_TransUnion]
    , [0_Experian]
	, [0_Equifax]
	, [1_TransUnion]
	, [1_Experian]
	, [1_Equifax]
	, [2_TransUnion]
	, [2_Experian]
	, [2_Equifax]




