use integra
go

WITH tt_main--turnaround time start (uploaded)
		AS
		(
		SELECT
				 
			-- lm.loanid							AS	[Loan #]
			clm.loanrecordid					AS	[loanrecordid]
			--,clm.collateralconditions			AS	[Number Of Conditions-All]
			,lc.condname						AS	[Condition]
			,lc.condid							AS	[Condid]

			,IIF(lch.datefirstentered='1800', NULL, lch.datefirstentered) 
												AS	[Date Cond Entered]

			--,IIF(lch.datecompleted='1800', NULL, lch.datecompleted)  
			--									AS	[Date Cond Completed]

			,ROW_NUMBER() OVER (PARTITION BY clm.loanrecordid, lc.condid ORDER BY lch.datefirstentered DESC)
												AS	[Date Sorter]
			,lch.csid							AS	[Cond Status]
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
		--and clm.loanrecordid='61096'
		) 

,tt_new--turnaround time start (New)
		AS
		(
		SELECT
				
			  clm.loanrecordid					AS	[loanrecordid]

			,lc.condname						AS	[Condition]
			,lc.condid							AS	[Condid]
			 ,IIF(lch.datecompleted='1800', NULL, lch.datecompleted)  
												AS	[Date Cond Completed]
			 ,ROW_NUMBER() OVER (PARTITION BY clm.loanrecordid, lc.condid ORDER BY lch.datefirstentered DESC)
												AS	[Date Sorter]
			,lch.csid							AS	[Cond Status]
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
		AND lch.csid IN (5)--New
		--and clm.loanrecordid='61096'
		) 


,tt_ref--turnaround time end (Reviewed-Errors Found)
		AS
		(
		SELECT
				
			  clm.loanrecordid					AS	[loanrecordid]

			,lc.condname						AS	[Condition]
			,lc.condid							AS	[Condid]
			 ,IIF(lch.datecompleted='1800', NULL, lch.datecompleted)  
												AS	[Date Cond Completed]
			 ,ROW_NUMBER() OVER (PARTITION BY clm.loanrecordid, lc.condid ORDER BY lch.datefirstentered DESC)
												AS	[Date Sorter]
			,lch.csid							AS	[Cond Status]
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
		AND lch.csid IN (3, 6)--Reviewed - Errors Found, Uploaded
		--and clm.loanrecordid='61096'
		) 

,tt_satisf--turnaround time end (Satisfied)
		AS
		(
		SELECT
				
			  clm.loanrecordid					AS	[loanrecordid]
			,lc.condname						AS	[Condition]
			,lc.condid							AS	[Condid]
			 ,IIF(lch.datefirstentered='1800', NULL, lch.datefirstentered) 
												AS	[Date Cond Entered]
			 --,IIF(lch.datecompleted='1800', NULL, lch.datecompleted)  
				--								AS	[Date Cond Completed]
			 ,ROW_NUMBER() OVER (PARTITION BY clm.loanrecordid, lc.condid ORDER BY lch.datefirstentered DESC)
												AS	[Date Sorter]
			,lch.csid							AS	[Cond Status]
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
		AND lch.csid IN (2, 6)--Satisfied, Uploaded
		--and clm.loanrecordid='61096'
		) 

,lvl1 AS
	(

				SELECT	
					*
				FROM tt_main
				WHERE [Date Sorter]=1
				
UNION
				
				SELECT
					*
				FROM tt_satisf
				WHERE [Date Sorter]=1
					AND [Cond Status]=2
				
UNION
				
				SELECT
					*
				FROM tt_ref
				WHERE [Date Sorter]=1    
					AND [Cond Status]=3

UNION

				SELECT
					*
				FROM tt_new
				WHERE [Date Sorter]=1    

	)

,lvl_2 
	AS
	(

	SELECT 
	
		*
		,LEAD([Date Cond Entered]) OVER (PARTITION BY loanrecordid, condid ORDER BY [Date Cond Entered]) AS [Next Status]

	FROM lvl1
	WHERE [Cond Status]!=5 
	)

SELECT 
	* 
	, DATEDIFF(HOUR, [Date Cond Entered], [Next Status]) AS [T-A Time]
FROM lvl_2
WHERE [Next Status] is not null


