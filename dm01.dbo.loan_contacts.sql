
----__________________________________________________________________________________________________________________________________________________
--PART I - DECLARING A FULL DATE RANGE OF A PREVIOUS MONTH:

DECLARE @last_day date= dateadd(day, -(day(getdate())),getdate())
DECLARE @1st_day date=dateadd(day,-(day(dateadd(day,-(day(getdate())), getdate()))-1) ,dateadd(day,-(day(getdate())),getdate()));
--___________________________________________________________________________________________________________________________________________________



--___________________________________________________________________________________________________________________________________________________
--PART II - CTE THAT FOUNDS THE LAST PERSON WHO CHANGED A LOAN STATUS TO SUSP, COND APPR OR DENIED,
--EVALUATES EACH LOAN WITH BONUS POINTS (LOANS ADJ) & # OF LOANS:

WITH touch AS (
				--DECLARE @last_day date= dateadd(day, -(day(getdate())),getdate())
			--	DECLARE @1st_day date=dateadd(day,-(day(dateadd(day,-(day(getdate())), getdate()))-1) ,dateadd(day,-(day(getdate())),getdate()));
				SELECT 
					 [contact_name]
					,[loans_adjusted]
					,[prod]
					,[doc_type]
					,[duplicate_counter]=row_number() over (partition by [loan_id] order by [row_version])
					,[status_id]
					,[loan_status]
					,[loan_id]
					,[approval_date]
					,[date_status_entered]
					


				FROM (
								SELECT 

								 [contact_name]=lc.[Contact Name]
								,[approval_date]=cast(lm.approvaldate as date) 
								,[date_status_entered]=ls.datefirstentered 
								,[loan_id]=lm.loanid
								,[loan_status]=sls.statusdescription
								,[status_id]=ls.statusid
								,[row_version]=ls.issrowversion 
								,[doc_type]=sdt.doctypedesc
								,[prod]=prm.productdescription
								, CASE 
									WHEN prm.productdescription like '%FHA%' or prm.productdescription like '%Prime%Jumbo%'
									THEN '1.5'
									ELSE '1'
								END AS
								 [loans_adjusted] 

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
								WHERE ls.statusid in (181,182,184)
									
								) a

								WHERE
									--cast(a.[date_status_entered] as date)
									
									(
									(case 
										when cast([approval_date] as varchar (max))like '%1800%'
										then 'yes'
										else 'no'
										end)='yes' 
										or (cast([approval_date] as date)
									BETWEEN @1st_day AND @last_day
									)
									)	--need this case if a file wasn't approved at all (if it was approved then the approval date will be in the date range)
									and 
									cast([date_status_entered] as date) between @1st_day and @last_day
									
									
				)

--__________________________________________________________________________________________________________________________________________________


--PART III - CALCULATING THE TOTALS FROM THE CTE AND DECLARING THE AS_OF_DATE______________________________________________________________________:

SELECT 

	  [contact_name]
	 ,[approval_date]
	 ,[loan_id]=cast([loan_id] as int)
	 ,[loan_status]
	 ,[status_id]=cast([status_id] as int)
	 ,[doc_type]
	 ,[prod]
	 ,[loans_adjusted]=cast([loans_adjusted] as float)
	 ,[loans_adj_sum]=sum(cast([loans_adjusted] as float)) over (partition by [contact_name])
	 ,[loan_count]=count([loan_id]) over (partition by [contact_name])
	 ,[as_of_date]=@last_day
	 ,[date_status_entered]

FROM touch t
Where [duplicate_counter]=1


order by [contact_name]

--select year(1800-01-01)
--END

--select * from #db where id=
--create table #excel (id bigint)
--insert into #excel  values 

--(1056477)
--,(1056744)
--,(1056506)
--,(1056456)
--,(1056124)
--,(1056475)
--,(1056344)
--,(1056313)
--,(1056518)
--,(1056434)
--,(1056428)
--,(1056375)
--,(1056425)
--,(1056268)
--,(1055223)
--,(1055451)
--,(1050676)
--,(1055506)
--,(1055346)
--,(1055311)
--,(1055330)
--,(1055512)
--,(1055381)
--,(1055015)
--,(1055468)
--,(1055432)
--,(1054439)
--,(1055715)
--,(1055602)
--,(1055379)
--,(1052215)
--,(1055462)
--,(1055930)
--,(1053712)
--,(1055785)
--,(1055786)
--,(1055787)
--,(1053212)
--,(1055788)
--,(1055489)
--,(1054948)
--,(1056006)
--,(1055925)
--,(1055928)
--,(1055929)
--,(1056762)
--,(1056677)
--,(1056759)
--,(1056222)
--,(1056905)
--,(1056788)
--,(1056808)
--,(1056915)
--,(1057028)
--,(1056938)
--,(1057033)
--,(1057067)
--,(1057212)
--,(1057133)
--,(1057119)
--,(1057282)
--,(1057284)
--,(1056252)


--select * from #excel where id not in (select * from #db)











--select * from loan_contacts where [Loan #]='1048547'








































