use integra 
go

WITH col_team AS	
				(
				SELECT 
	    
					 [User ID]
					,loanrecordid

				FROM dm01.dbo.loan_contacts
				WHERE [User ID] in	   ('13052'
									   ,'18408'
									   ,'21194'
									   ,'22636'
									   ,'25109'
									   ,'25463'
									   ,'25497'
									   )
				)--collateral team members as of 01/24



, main AS
				(
				SELECT
				
					  lm.loanid							AS	[Loan #]
					 ,ct.									[User ID]	
					 ,clm.collateralconditions			AS	[Number Of Conditions-All]
					 ,lc.condname						AS	[Condition]
					 ,CASE 
						WHEN year(lch.datefirstentered)='1800'
						THEN NULL
						ELSE lch.datefirstentered
					 END								AS	[Date Cond Entered]
					,CASE
						WHEN year(lch.datecompleted)='1800'
						THEN NULL
						ELSE lch.datecompleted
					 END								AS	[Date Cond Completed]
					 ,ROW_NUMBER() OVER (PARTITION BY clm.loanrecordid, lc.condid ORDER BY lch.datefirstentered DESC)
															[Date Sorter]
					 ,lc.condid
					 ,sc.condalias
					 ,clm.loanrecordid
					 ,lch.csid							AS	[Status]
					 ,scs.csdesc
				
				FROM custom_loanmain					clm
				
				LEFT JOIN loan_main						lm
					ON lm.loanrecordid=clm.loanrecordid
				
				LEFT JOIN col_team						ct
					ON ct.loanrecordid=clm.loanrecordid
				
				LEFT JOIN loan_conditions				lc
					ON lc.loanrecordid=clm.loanrecordid
				
				LEFT JOIN setups_conditions				sc--condition on main cond screen
					ON lc.condid=sc.condid
				
				LEFT JOIN loan_condstatushistory		lch
					ON lch.loanrecordid=lc.loanrecordid
					AND lch.lcorder=lc.lcorder
				
				LEFT JOIN setups_conditionstatus		scs--condition status history
					ON scs.csid=lch.csid
					
				WHERE lm.loanrecordid not in (
												SELECT *
													FROM dm01.dbo.integra_test_loans)
				AND clm.collateralconditions>0 --show only loans that have conditions to review
				AND lm.loanid='1063118'
				AND sc.condalias='Collateral Underwriter'--Conditions category
				AND lc.state!='H'--only active conditioins ("H"are hidden autoconditions)
				--AND lc.csid=6--uploaded status
				AND lch.csid in (2,3,6)
				)
				
				
------------------------------------------------------MAIN SELECT

SELECT

	*
	

FROM main

--WHERE [Status] in (2,3)

--WHERE [Date Sorter]=1

--select 
--______________________________________________________________________________________________________________________________
use integra 
go

WITH col_team AS	
				(
				SELECT 
	    
					 [User ID]
					,loanrecordid

				FROM dm01.dbo.loan_contacts
				WHERE [User ID] in	   ('13052'
									   ,'18408'
									   ,'21194'
									   ,'22636'
									   ,'25109'
									   ,'25463'
									   ,'25497'
									   )
				)--collateral team members as of 01/24



, main AS
				(
				SELECT
				
					  lm.loanid							AS	[Loan #]
					 ,clm.loanrecordid					AS	[loanrecordid]
					 ,ct.									[User ID]	
					 ,clm.collateralconditions			AS	[Number Of Conditions-All]
					 ,lc.condname						AS	[Condition]

					 ,IIF(lch.datefirstentered='1800', NULL, lch.datefirstentered) 
														AS	[Date Cond Entered]

					 ,IIF(lch.datecompleted='1800', NULL, lch.datecompleted)  
														AS	[Date Cond Completed]

					 ,ROW_NUMBER() OVER (PARTITION BY clm.loanrecordid, lc.condid ORDER BY lch.datefirstentered DESC)
														AS	[Date Sorter]
					 ,lc.condid
					 ,sc.condalias
					 ,lch.csid							AS	[Status]
					 ,scs.csdesc
				
				FROM custom_loanmain					clm
				
				LEFT JOIN loan_main						lm
					ON lm.loanrecordid=clm.loanrecordid
				
				LEFT JOIN col_team						ct
					ON ct.loanrecordid=clm.loanrecordid
				
				LEFT JOIN loan_conditions				lc
					ON lc.loanrecordid=clm.loanrecordid
				
				LEFT JOIN setups_conditions				sc--condition on main cond screen
					ON lc.condid=sc.condid
				
				LEFT JOIN loan_condstatushistory		lch
					ON lch.loanrecordid=lc.loanrecordid
					AND lch.lcorder=lc.lcorder
				
				LEFT JOIN setups_conditionstatus		scs--condition status history
					ON scs.csid=lch.csid
					
				WHERE lm.loanrecordid not in (
												SELECT *
													FROM dm01.dbo.integra_test_loans)
				AND clm.collateralconditions>0 --show only loans that have conditions to review
				AND lm.loanid='1063118'
				AND sc.condalias='Collateral Underwriter'--Conditions category
				AND lc.state!='H'--only active conditioins ("H"are hidden autoconditions)
				--AND lc.csid=6--uploaded status
				AND lch.csid in (3)
				)
				
				
------------------------------------------------------MAIN SELECT

SELECT

	*
	,b.[Date Cond Entered]

FROM main			m

LEFT JOIN 




------------------------------------------------------------------------------------------------------------------------------------------------------
WITH tt_main--turnaround time start (uploaded)
		AS
		(
		SELECT
				
			 lm.loanid							AS	[Loan #]
			,clm.loanrecordid					AS	[loanrecordid]
			,clm.collateralconditions			AS	[Number Of Conditions-All]
			,lc.condname						AS	[Condition]

			,IIF(lch.datefirstentered='1800', NULL, lch.datefirstentered) 
												AS	[Date Cond Entered]

			,IIF(lch.datecompleted='1800', NULL, lch.datecompleted)  
												AS	[Date Cond Completed]

			,ROW_NUMBER() OVER (PARTITION BY clm.loanrecordid, lc.condid ORDER BY lch.datefirstentered DESC)
												AS	[Date Sorter]
			,lch.csid
			,lm.loanid

		FROM custom_loanmain					clm

		LEFT JOIN loan_main						lm
			ON lm.loanrecordid=clm.loanrecordid

		LEFT JOIN loan_conditions				lc
			ON lc.loanrecordid=clm.loanrecordid

		LEFT JOIN setups_conditions				sc--condition on main cond screen
			ON lc.condid=sc.condid

		LEFT JOIN loan_condstatushistory		lch
			ON lch.loanrecordid=lc.loanrecordid
			AND lch.lcorder=lc.lcorder

		LEFT JOIN setups_conditionstatus		scs--condition status history
			ON scs.csid=lch.csid
	
		WHERE lm.loanrecordid not in (
										SELECT *
											FROM dm01.dbo.integra_test_loans)
		AND sc.condalias='Collateral Underwriter'--Conditions category
		AND lc.state!='H'--only active conditioins ("H"are hidden autoconditions)
		--AND lc.csid=6--uploaded status
		AND lch.csid = 6--uploaded
		and clm.loanrecordid='61096'
		) 

,tt_ref--turnaround time start (Reviewed-Errors Found)
		AS
		(
		SELECT
				
			  clm.loanrecordid					AS	[loanrecordid]

			 --,IIF(lch.datefirstentered='1800', NULL, lch.datefirstentered) 
				--								AS	[Date Cond Entered]
			 ,IIF(lch.datecompleted='1800', NULL, lch.datecompleted)  
												AS	[Date Cond Completed]
			 ,ROW_NUMBER() OVER (PARTITION BY clm.loanrecordid, lc.condid ORDER BY lch.datefirstentered DESC)
												AS	[Date Sorter]
			,lch.csid
			,lm.loanid

		FROM custom_loanmain					clm

		LEFT JOIN loan_main						lm
			ON lm.loanrecordid=clm.loanrecordid

		LEFT JOIN loan_conditions				lc
			ON lc.loanrecordid=clm.loanrecordid

		LEFT JOIN setups_conditions				sc--condition on main cond screen
			ON lc.condid=sc.condid

		LEFT JOIN loan_condstatushistory		lch
			ON lch.loanrecordid=lc.loanrecordid
			AND lch.lcorder=lc.lcorder

		LEFT JOIN setups_conditionstatus		scs--condition status history
			ON scs.csid=lch.csid
	
		WHERE lm.loanrecordid not in (
										SELECT *
											FROM dm01.dbo.integra_test_loans)
		AND sc.condalias='Collateral Underwriter'--Conditions category
		AND lc.state!='H'--only active conditioins ("H"are hidden autoconditions)
		--AND lc.csid=6--uploaded status
		AND lch.csid = 3--Reviewed - Errors Found
		and clm.loanrecordid='61096'
		) 

,tt_satisf--turnaround time start (Satisfied)
		AS
		(
		SELECT
				
			  clm.loanrecordid					AS	[loanrecordid]

			 ,IIF(lch.datefirstentered='1800', NULL, lch.datefirstentered) 
												AS	[Date Cond Entered]
			 --,IIF(lch.datecompleted='1800', NULL, lch.datecompleted)  
				--								AS	[Date Cond Completed]
			 ,ROW_NUMBER() OVER (PARTITION BY clm.loanrecordid, lc.condid ORDER BY lch.datefirstentered DESC)
												AS	[Date Sorter]
			,lch.csid
			,lm.loanid

		FROM custom_loanmain					clm

		LEFT JOIN loan_main						lm
			ON lm.loanrecordid=clm.loanrecordid

		LEFT JOIN loan_conditions				lc
			ON lc.loanrecordid=clm.loanrecordid

		LEFT JOIN setups_conditions				sc--condition on main cond screen
			ON lc.condid=sc.condid

		LEFT JOIN loan_condstatushistory		lch
			ON lch.loanrecordid=lc.loanrecordid
			AND lch.lcorder=lc.lcorder

		LEFT JOIN setups_conditionstatus		scs--condition status history
			ON scs.csid=lch.csid
	
		WHERE lm.loanrecordid not in (
										SELECT *
											FROM dm01.dbo.integra_test_loans)
		AND sc.condalias='Collateral Underwriter'--Conditions category
		AND lc.state!='H'--only active conditioins ("H"are hidden autoconditions)
		--AND lc.csid=6--uploaded status
		AND lch.csid = 2--Satisfied
		and clm.loanrecordid='61096'
		) 
	
--MAIN SELECT

SELECT
	
	main.*

FROM tt_main				main

--LEFT JOIN tt_ref			ref
--	ON ref.loanrecordid=main.loanrecordid
--	AND ref.[Date Sorter]=1

--LEFT JOIN tt_satisf			stsf
--	ON stsf.loanrecordid=main.loanrecordid
--	AND stsf.[Date Sorter]=1

WHERE main.[Date Sorter]=1