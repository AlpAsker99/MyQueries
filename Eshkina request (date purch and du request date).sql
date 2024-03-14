SELECT 
	  lm.loanid											[Loan #]
	, CASE 
		WHEN lm.datepurchased like '%1800%' THEN null
		ELSE lm.datepurchased
		END AS											[Date Purchased]

	, CASE 
		WHEN du.lastrequestdate like '%1800%' THEN null
		ELSE du.lastrequestdate
		END AS											[Last Request Date]

FROM loan_main											lm

LEFT JOIN du_information								du
	ON du.loanrecordid = lm.loanrecordid

--select * from INFORMATION_SCHEMA.COLUMNS
--where COLUMN_NAME like '%request%'

SELECT 
	  oc5.Loan_id						[Loan #]
	, oc5.Post_Closing_Purchased_Date	[Date Purchased]

FROM dm01.dbo.OC_5 oc5

	