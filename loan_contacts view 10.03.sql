select * from [INFORMATION_SCHEMA].[COLUMNS]
WHERE TABLE_NAME LIKE'%customer_main%'
AND COLUMN_NAME like '%eamil%'

select top 100* from rolodex_entity re LEFT JOIN loan_channelcontacts	lcc ON lcc.entityid = re.entityid where loanrecordid = 1358

select firstname,lastname, contactcategoryid
--firstname ,contactcategoryid, lcc.associationid, lm.loanid
from rolodex_contacts rc  JOIN loan_channelcontacts	lcc ON lcc.contactid= rc.contactid 
--LEFT JOIN loan_main					lm
--ON lm.loanrecordid = lcc.loanrecordid 
where lcc.loanrecordid = 52349 
--and lcc.contactcategoryid=49
and firstname like '%Miguel%'
WITH rc_ae AS (
				SELECT 
)
--====================================================--====================================================--====================================================--====================================================
alter view loan_contacts as 
					WITH cte_contacts AS (

								SELECT 

									  CASE	
										WHEN rc.middlename is not null and rc.middlename not like '%-%'
										THEN rc.firstname +' '+rc.middlename+' '+rc.lastname
										ELSE rc.firstname +' '+rc.lastname
										END AS									[Contact Name]
									 , rc.contactid								[Contact ID]
									 , row_number() over (partition by lm.loanid, lcc.contactcategoryid order by rc.issrowversion desc)			
																				[Duplicate Counter]
									 ,re.name									[Company Name]
									 , lm.loanid								[Loan #]
									 , lm.loanrecordid							[loanrecordid]
									 , lcc.contactcategoryid					[Contact Category ID]
									 , rc.emailaddress							[Email Address]
									 , rc.addressline1							[Address #1]
									 , rc.addressline2							[Address #2]
									 , rc.city									[City]
									 , rc.state									[State]
									 , rc.zipcode								[ZIP Code]
									 , rc.title									[Title]
									 , CASE
										WHEN lcc.contactcategoryid = 1 THEN 'Appraisal Firm-Appraiser'
										WHEN lcc.contactcategoryid = 21 THEN 'Settlement Agency-Settlement Agent'
										WHEN lcc.contactcategoryid = 27 THEN 'Closer'
										WHEN lcc.contactcategoryid = 38 THEN 'UW1'
										WHEN lcc.contactcategoryid = 48 THEN 'RE Buyers Agency-Buyer Agent'
										WHEN lcc.contactcategoryid = 49 THEN 'LO'
										WHEN lcc.contactcategoryid = 50 THEN 'Broker Processor 1'
										WHEN lcc.contactcategoryid = 99 THEN 'AE'
										WHEN lcc.contactcategoryid = 64 THEN 'Disclosure'
										WHEN lcc.contactcategoryid = 65 THEN 'Funder-Docs Review'
										WHEN lcc.contactcategoryid = 67 THEN 'Quelity Control'
										WHEN lcc.contactcategoryid = 68 THEN 'Senior UW'
										WHEN lcc.contactcategoryid = 95 THEN 'Post Closer'
										WHEN lcc.contactcategoryid = 101 THEN 'Whalesale Manager'
										WHEN lcc.contactcategoryid = 110 THEN 'UW Support'
										WHEN lcc.contactcategoryid = 111 THEN 'Collateral Underwriter'
										WHEN lcc.contactcategoryid = 112 THEN 'Broker Processor 2'
										WHEN lcc.contactcategoryid = 114 THEN 'Funder-Wire Request'
										WHEN lcc.contactcategoryid = 118 THEN 'Wholesale Loan Processor'
										END AS									[Role]				
						
								FROM integra.dbo.rolodex_contacts				rc
					
								LEFT JOIN integra.dbo.loan_channelcontacts		lcc
									ON lcc.contactid = rc.contactid

								LEFT JOIN integra.dbo.loan_main					lm
									ON lm.loanrecordid = lcc.loanrecordid

								LEFT JOIN integra.dbo.rolodex_entity			re
									ON lcc.entityid = re.entityid

								WHERE lcc.contactcategoryid in (49, 99, 64, 38, 68, 101, 118, 50, 110, 111, 27, 67, 65, 114, 95, 1, 21, 112)
								AND lm.loanid!='Not Assigned'

								)--integra loan contact section


					,cte_borr AS (
								SELECT 
									 lm.loanid									[Loan #]
									,row_number() over (partition by lm.loanid order by cm.issrowversion desc)
																				[Borrower Sorter]
									,cm.firstname+' '+cm.middlename+' '+cm.lastname
																				[Borrower Name]
									,cm.ssnumber								[SSN]
									,cm.email									[Email]

								FROM integra.dbo.loan_main						lm

								LEFT JOIN integra.dbo.customer_group			cg
									ON cg.customergroupid=lm.customergroupid
						
								LEFT JOIN integra.dbo.customer_main				cm
									ON cm.customerrecordid=cg.customerrecordid

								)
				   
				   
				   ,cte_lo_comp AS (
								 SELECT
									 name										[Company Name]
									, row_number() over (partition by lm.loanid,lcc.entitycategoryid order by lm.issrowversion desc  )			
																				[Duplicate Counter]
									,lm.loanid									[Loan #]
									,lcc.entitycategoryid						[Entity Category ID]
									,re.entityid								[Entity ID]
									, lm.issrowversion							[Row Version]
									, lm.loanrecordid
								FROM integra.dbo.rolodex_entity					re

								LEFT JOIN integra.dbo.loan_channelcontacts		lcc
									ON lcc.entityid = re.entityid

								LEFT JOIN integra.dbo.loan_main					lm
									ON lm.loanrecordid = lcc.loanrecordid

								WHERE lcc.entitycategoryid=43 -- the LO company category number

								) --Companyies
	

SELECT 

	 cont.[Loan #]	
	,cont.[loanrecordid]
	,cont.[Company Name]
	,comp.[Company Name]		  AS [LO Company Key]
	,[Contact Name]
	,[Role]
	,[Contact ID]
	,cont.[Email Address] 
	,[Address #1]
	,[Address #2]
	,[City]
	,[State]
	,[ZIP Code]
	,cont.[Contact Category ID]
	,bor1.[Borrower Name] AS [Borrower #1 Name]
	,bor2.[Borrower Name] AS [Borrower #2 Name]
	,bor1.[SSN]			  AS [Borrower #1 SSN]
	,bor2.[SSN]			  AS [Borrower #2 SSN]
	,bor1.[Email]		  AS [Borrower #1 Email]
	,bor2.[Email]		  AS [Borrower #2 Email]

FROM cte_contacts									cont

LEFT JOIN cte_borr									bor1
	ON bor1.[Loan #]=cont.[Loan #]
	AND [Borrower Sorter]=1

LEFT JOIN cte_borr									bor2
	ON bor2.[Loan #]=cont.[Loan #]
	AND bor2.[Borrower Sorter]=2

LEFT JOIN cte_lo_comp								comp
	ON comp.[Loan #]=cont.[Loan #]
	AND comp.[Duplicate Counter]=1

WHERE cont.[Duplicate Counter]=1



select  * from dm01.dbo.loan_contacts where [Loan #] ='1054136' order by [Contact Name]


	
--====================================================--====================================================--====================================================--====================================================				



  WITH re_comp AS ( 
					SELECT
						 name										[Company Name]
						, row_number() over (partition by lm.loanid,lcc.entitycategoryid order by lm.issrowversion desc  )			
																	[Duplicate Counter]
						,lm.loanid									[Loan #]
						,lcc.entitycategoryid						[Contact Category ID]
						,re.entityid								[Entity ID]
						, lm.issrowversion							[Row Version]
						, lm.loanrecordid
					FROM rolodex_entity					re

					LEFT JOIN loan_channelcontacts		lcc
						ON lcc.entityid = re.entityid

					LEFT JOIN loan_main					lm
						ON lm.loanrecordid = lcc.loanrecordid

					WHERE lcc.entitycategoryid=43 -- the LO company category number



					) --Companyies
			
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



--======================================================--======================================================--======================================================--======================================================
SELECT 
	  lm.loanid
	, lc.[Contact Name]
	, lc.[Role]
	, lc.[Contact Category ID]
FROM integra.dbo.loan_main	lm 

LEFT JOIN loan_contacts		lc
	ON lm.loanid=lc.[Loan #]
	AND lc.[Role]='AE' 
	--or we can specify a [Contact Category ID]  "AND lc.[Contact Category ID]=99"

WHERE lm.loanid = '1003581'


[2:18 PM] Vera Popova

select name
, lc.[Company Name]
, lc.[Contact Name]
, contactid 

from rolodex_entity,
loan_channelcontacts,
dm01.dbo.loan_contacts as lc

where rolodex_entity.entityid=loan_channelcontacts.entityid

and loan_channelcontacts.contactid=lc.[Contact ID]