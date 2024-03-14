USE [dm01]
GO

/****** Object:  StoredProcedure [dbo].[usp_UW_bonus_current_mnth]    Script Date: 2/27/2024 3:34:35 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO





CREATE procedure [dbo].[usp_UW_bonus_current_mnth]

AS
BEGIN
--===========================
--Sr.UW bonus
--Author: Aleskerov Nurlan
--Script Date: 11-24-2023
--===========================



----__________________________________________________________________________________________________________________________________________________
--PART I - DECLARING A FULL DATE RANGE OF A PREVIOUS MONTH:
DECLARE @last_day date= dateadd(day, -(day(getdate())),getdate())
DECLARE @1st_day date=dateadd(day,-(day(dateadd(day,-(day(getdate())), getdate()))-1) ,dateadd(day,-(day(getdate())),getdate()));


--___________________________________________________________________________________________________________________________________________________
--PART II - CTE THAT FOUNDS THE LAST PERSON WHO CHANGED A LOAN STATUS TO SUSP, COND APPR OR DENIED,
--EVALUATES EACH LOAN WITH BONUS POINTS (LOANS ADJ) & # OF LOANS:

WITH touch AS (
				--DECLARE @last_day date= dateadd(day, -(day(getdate())),getdate())
				--DECLARE @1st_day date=dateadd(day,-(day(dateadd(day,-(day(getdate())), getdate()))-1) ,dateadd(day,-(day(getdate())),getdate()));
							SELECT 

					 [contact_name]
					,[User ID]
					,[loans_adjusted]
					,[prod]
					,[doc_type]
					,[duplicate_counter]
					,[status_id]
					,[loan_status]
					,[loan_id]
					,[approval_date]
					,cast([date_status_entered]as date) as [date_entered] 

				FROM ( 
					--DECLARE @last_day date= dateadd(day, -(day(getdate())),getdate())
					--DECLARE @1st_day date=dateadd(day,-(day(dateadd(day,-(day(getdate())), getdate()))-1) ,dateadd(day,-(day(getdate())),getdate()));
								SELECT 

								 [contact_name]=lc.[Contact Name]
								,[approval_date]=cast(lm.approvaldate as date) 
								,[date_status_entered]=ls.datefirstentered 
								,[loan_id]=lm.loanid
								,[loan_status]=sls.statusdescription
								,[status_id]=ls.statusid
								,[row_version]=ls.issrowversion 
								,[duplicate_counter]=row_number() over (partition by lm.loanid order by ls.datefirstentered) 
								,[doc_type]=sdt.doctypedesc
								,[prod]=prm.productdescription
								, CASE 
									WHEN prm.productdescription like '%FHA%' or prm.productdescription like '%Prime%Jumbo%'
									THEN '1.5'
									ELSE '1'
								END AS
								 [loans_adjusted] 
								 ,lc.[User ID]

								FROM integra.dbo.loan_status ls  

								LEFT JOIN integra.dbo.loan_main lm 
									ON lm.loanrecordid=ls.loanrecordid

								LEFT JOIN integra.dbo.loan_postclosing lpc
									ON lpc.loanrecordid=lm.loanrecordid

								LEFT JOIN integra.dbo.loan_automatedunderwriting lau
									ON lau.loanrecordid=lm.loanrecordid

								LEFT JOIN integra.dbo.setups_doctype sdt
									ON sdt.doctypeid=lau.documenttype

								LEFT JOIN integra.dbo.product_main prm
									ON lm.productid=prm.productid

								LEFT JOIN integra.dbo.setups_loanstatus sls
									ON sls.statusid=ls.statusid

								JOIN (select 
												 distinct [Contact Name]
												,[User ID] 
									from dm01.dbo.loan_contacts 
									where [Contact Category ID]=68
									) lc--the list of sr uw's with user id's
									ON lc.[User ID]=ls.useridfirstentered

									WHERE ls.statusid in (181,182,184)--cond approved, suspended, denied	
						) a

								WHERE
									CAST([date_status_entered] AS DATE) BETWEEN @1st_day AND @last_day
									AND [duplicate_counter]=1
				)
									
									
				

--__________________________________________________________________________________________________________________________________________________
--PART III - CALCULATING THE TOTALS FROM THE CTE AND DECLARING THE AS_OF_DATE______________________________________________________________________:

SELECT 

	  [contact_name]=replace([contact_name],'  ',' ')
	  ,[User ID]
	 --,[approval_date]
	 ,[loan_id]=cast([loan_id] as int)
	 --,[loan_status]
	 --,[status_id]=cast([status_id] as int)
	 ,[doc_type]
	 ,[prod]
	 ,[loans_adjusted]=cast([loans_adjusted] as float)
	 ,[loans_adj_sum]=sum(cast([loans_adjusted] as float)) over (partition by [contact_name])
	 ,[loan_count]=count([loan_id]) over (partition by [contact_name])
	 ,[date_entered]
	 ,[as_of_date]=@1st_day

FROM touch t


--__________________________________________________________________________________________________________________________________________________
--PART IV - ADDING MANUALS__________________________________________________________________________________________________________________________:

UNION
--DECLARE @last_day date= dateadd(day, -(day(getdate())),getdate())
--DECLARE @1st_day date=dateadd(day,-(day(dateadd(day,-(day(getdate())), getdate()))-1) ,dateadd(day,-(day(getdate())),getdate()));
	SELECT --to join uw names
		 
		  REPLACE(lc1.[Contact Name], '  ', '')											AS	[contact_name]	
		  ,																					[User ID]
		 ,c.																				[loan_id]
		 --,null																			AS	[loan_status]
		 ,c.																				[doc_type]
		 ,c.																				[prod]
		 ,CAST(c.[loans_adjusted] AS FLOAT)												AS	[loans_adjusted]
		 ,SUM(CAST(c.[loans_adjusted] AS FLOAT)) OVER (PARTITION BY lc1.[Contact Name])	AS	[loans_adj_sum]
		 ,COUNT(c.[loan_id]) OVER (PARTITION BY lc1.[Contact Name])						AS	[loan_count]
		 ,																					[date_enterred]
		 ,@1st_day																		AS	[as_of_date]
		 
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
										SELECT--to filter out what we dont need

											 lm.loanid								AS	[loan_id]
											,lcom.userid
											,lcom.vt_vartextid						AS	[comment]
											,CASE
												WHEN lm.loanid in ('1058107') --here you can add manuals comments for which were added out of a date range
												THEN '2023-11-17'
												ELSE lcom.datetimeadded
											 END									AS	[date_enterred]
											,prm.productdescription					AS	[product_desc]
											,sls.statusdescription					AS	[loan_status]
											,sdt.doctypedesc						AS	[doc_type]
											,prm.productdescription					AS	[prod]

										FROM integra.dbo.loan_comments				lcom

										LEFT JOIN integra.dbo.loan_main				lm
											ON lm.loanrecordid=lcom.recordid

										LEFT JOIN integra.dbo.loan_status ls
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
		 and [User ID]!=0
		 ) lc1--the list of sr uw's with user id's
		ON lc1.[User ID]=c.[user_id] 

		end 
GO

