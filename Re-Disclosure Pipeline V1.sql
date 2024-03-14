use integra 
go
------------------- MAIN dataset for Re-Disclosure Bonus report -------------------------------
/*
	Author: Aleskerov Nurlan

	Script Last UPD Date: 02/13/2024

	Description: This script is to calculate and insert Re-Disclosure bonus data in 
	"rd_bonus_history" table every month. 

	Steps: Finding the category of the docs in Doc Magic that we need (CD), defining initials,
	filterring by comment and date.
*/
--------------------------------------- CTE's --------------------------------------------------

DECLARE @current_date date = dateadd(day,-(day(dateadd(day,-(day(getdate())), getdate()))-1) ,dateadd(day,-(day(getdate())),getdate()));

	WITH rd_ass 
		AS
		(
		SELECT 
			
			  [loanrecordid] 
			, [User ID] 

		FROM dm01.dbo.loan_contacts 
		
		WHERE [contact category id]=92
			AND [contact name] != '-' 

		UNION--to add loans with manual assignment method (Correspondant files)

		SELECT
				
				RTRIM(
					LTRIM(
						SUBSTRING(
								 vt_vartextid
								,PATINDEX(
									'% [0-9][0-9][0-9]%'
									,vt_vartextid
										)
								,LEN(CAST(vt_vartextid AS VARCHAR(MAX)))
								)
							)
						)			AS	[Contact Name]
						,recordid	AS	[loanrecordid]

			FROM loan_comments
			
			WHERE vt_vartextid LIKE '%assigned%rd%[0-9]' 

		)--The list of the assigned Re-Disclosures
		
	,rd_names
		AS
		(
		SELECT

			 DISTINCT [Contact Name]
			,		  [User ID]

		FROM dm01.dbo.loan_contacts
			
		WHERE [contact category id]=92
			AND [contact name] != '-'
		)
	
	
	,sorterr 
		AS
		(
		SELECT
	
			lm.loanid
			--,ldm.*
			,ldm.datecreated													 [Date Issued]
			,ROW_NUMBER() OVER (PARTITION BY lm.loanid ORDER BY ldm.datecreated) [sorter]
			,t.taskname
			,rd_n.[Contact Name]											AS	[Re-Disclosure Specialist]
	
		FROM loan_docimaging						ldm 
			
		LEFT JOIN tasks								t
			ON t.taskid=ldm.taskid
		
		INNER JOIN									rd_ass
			ON rd_ass.loanrecordid=ldm.loanrecordid

		LEFT JOIN  rd_names							rd_n
			ON rd_n.[User ID]=rd_ass.[User ID]
		
		LEFT JOIN loan_main							lm
			ON lm.loanrecordid=ldm.loanrecordid
		
		WHERE t.taskid=2000153--'Document Type - Closing Disclosure'
			AND comment='Closing Disclosure'--making sure the doc uploaded as CD is indeed a CD
		)

---------------------------------------- MAIN SELECT -------------------------------------------

SELECT 
	
	 *
	,COUNT(loanid) OVER (PARTITION BY [Re-Disclosure Specialist]) AS [# Of Loans]
	,@current_date												  AS [As Of Date]
FROM sorterr

WHERE [sorter]=1 --sorting out revised CD's to have only initials
	AND YEAR([Date Issued])=YEAR(@current_date)
	AND MONTH([Date Issued])=MONTH(@current_date)

ORDER BY [# Of Loans]


	