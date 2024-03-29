DECLARE @last_day date= dateadd(day, -(day(getdate())),getdate())
DECLARE @1st_day date=dateadd(day,-(day(dateadd(day,-(day(getdate())), getdate()))-1) ,dateadd(day,-(day(getdate())),getdate()));

						
	SELECT --to join uw names
		 
		  lc1.[Contact Name]																													
		 ,c.																				[loan_id]
		 ,null																			AS	[loan_status]
		 ,c.																				[doc_type]
		 ,c.																				[prod]
		 ,CAST(c.[loans_adjusted] AS FLOAT)												AS	[loans_adjusted]
		 ,SUM(CAST(c.[loans_adjusted] AS FLOAT)) OVER (PARTITION BY lc1.[Contact Name])	AS	[loans_adj_sum]
		 ,COUNT(c.[loan_id]) OVER (PARTITION BY lc1.[Contact Name])						AS	[loan_count]
		 ,@last_day																		AS	[as_of_date]
	FROM (
						SELECT --to sort out duplicates and select the period we need
	

																									[loan_id]
							 ,ltrim(right((rtrim(cast([comment]as varchar(max)))),5))			AS	[user_id]
							 ,																		[date_enterred]
							 , CASE 
									WHEN [product_desc] like '%FHA%' or [product_desc] like '%Prime%Jumbo%'
									THEN '1.5'
									ELSE '1'
								END																AS	[loans_adjusted]
							,																		[loan_status]
							,																		[doc_type]
							,																		[prod]
																								 


						FROM (
								SELECT --to count duplicates
									 a.*
									,ROW_NUMBER() OVER (PARTITION BY [loan_id ] ORDER BY [date_enterred])
																					AS	[duplicate_counter]
								FROM (
										SELECT--to filter out we dont need

											 lm.loanid								AS	[loan_id]
											,lcom.userid
											,lcom.vt_vartextid						AS	[comment]
											,cast(lcom.datetimeadded as date)		AS	[date_enterred]
											,prm.productdescription					AS	[product_desc]
											,sls.statusdescription					AS	[loan_status]
											,sdt.doctypedesc						AS	[doc_type]
											,prm.productdescription					AS	[prod]

										FROM loan_comments				lcom

										LEFT JOIN loan_main				lm
											ON lm.loanrecordid=lcom.recordid

										LEFT JOIN loan_status ls
											ON lm.loanrecordid=ls.loanrecordid
										
										LEFT JOIN integra.dbo.setups_loanstatus sls
											ON sls.statusid=ls.statusid

										LEFT JOIN integra.dbo.product_main prm
											ON lm.productid=prm.productid															
													
										LEFT JOIN integra.dbo.loan_automatedunderwriting lau
											ON lau.loanrecordid=lm.loanrecordid
										
										LEFT JOIN integra.dbo.setups_doctype sdt
											ON sdt.doctypeid=lau.documenttype

										WHERE 
										lcom.vt_vartextid like '%uw%completed%by%'
										and right(cast(lcom.vt_vartextid as varchar(max)), 1) like '[0-9]'

										) a 		
										
							 ) b
							 WHERE [duplicate_counter]=1
							 AND [date_enterred] between @1st_day and @last_day	
		) c

	JOIN (select 
	 		 distinct [Contact Name]
	 		,[User ID] 
		 from dm01.dbo.loan_contacts 
		 where [Contact Category ID]=68
		 ) lc1--the list of sr uw's with user id's
		ON lc1.[User ID]=c.[user_id]
	
										

							


	
