-- closing pipeline
select 
lm.loanid as LoanID,
lm.loanamount as Amount,
pm.productalias as Product,
sls.statusdescription as Status,
ls.datefirstentered as [Entered Date],
prm.state as State,
ppt.typedescription as Purpose,
--lm.refipurpose
cm.firstname+' '+cm.lastname as Customer,
sbc.channeldescription as Channel
,lm.businesschannelid

from loan_main lm
left join setups_loanstatus sls
on sls.statusid=lm.statusid
left join product_main pm
on pm.productid=lm.productid
left join loan_status ls
on ls.lenderdatabaseid=lm.lenderdatabaseid and lm.loanrecordid=ls.loanrecordid and lm.statusid=ls.statusid and year(ls.datecompleted)=1800
left join property_main prm
on prm.lenderdatabaseid=lm.lenderdatabaseid and prm.propertyrecordid=lm.propertyrecordid
left join product_purposetype ppt
on ppt.purposetypeid=lm.purposetypeid
left join loan_automatedunderwriting lau
on lau.lenderdatabaseid=lm.lenderdatabaseid and lau.loanrecordid=lm.loanrecordid
left join customer_group cg
on lm.customergroupid=cg.customergroupid and lm.lenderdatabaseid=cg.lenderdatabaseid and cg.primarycustomer='Y'
left join customer_main cm
on cm.customerrecordid=cg.customerrecordid 
left join setups_businesschannels sbc
ON lm.businesschannelid = sbc.channelid
where ( (lm.statusid in (187,190,191,193) and lm.loanid not in (
	select 
	lm.loanid
	from loan_main lm
	left join loan_channelcontacts lcc
	on lcc.lenderdatabaseid=lm.lenderdatabaseid and lm.loanrecordid=lcc.loanrecordid
	left join rolodex_contacts rc
	on rc.contactid=lcc.contactid
	left join security_groupsjoin sgj
	on sgj.userid=rc.userid
	where sgj.groupid in (34,35)
)
) or lm.statusid in (188))
and lm.loanrecordid not in (select loanrecordid from loan_channelentities where entityid = 7595) and lm.loanrecordid not in (
	select loanrecordid
	from loan_main lm
	left join customer_group cg
	on cg.lenderdatabaseid=lm.lenderdatabaseid and lm.customergroupid=cg.customergroupid and cg.primarycustomer='Y'
	left join customer_main cm
	on cm.customerrecordid=cg.customerrecordid and cm.lenderdatabaseid=cg.lenderdatabaseid
	where cm.lastname in ('Borrower','Sample','America','DELETE','Test','Customer','Homeowner')
) and lm.loanid not in (
select 
	lm.loanid
	from loan_main lm
	left join loan_channelcontacts lcc
	on lcc.lenderdatabaseid=lm.lenderdatabaseid and lm.loanrecordid=lcc.loanrecordid and lcc.associationid = '2'
	left join rolodex_contacts rc
	on rc.contactid=lcc.contactid and rc.userid = 0 and rc.lastname != '[Closer]'
	where rc.lastname is not null) 
	
   and lm.businesschannelid in (1,10,11)
and lm.loanid not in (
select
	lm.loanid
	from loan_main lm
	LEFT JOIN setups_businesschannels sbc
	ON lm.businesschannelid = sbc.channelid
	WHERE sbc.channeldescription like '%corr%' 
	AND sls.statusid NOT IN (191,  194, 195, 196, 197, 198))

	and lm.loanid not in 
							(
							SELECT 
								lm.loanid
							FROM loan_main lm
							LEFT JOIN setups_loanstatus sls
								ON lm.statusid=sls.statusid
							WHERE lm.businesschannelid=11
							and sls.statusid=191
							)-- sorting out minicors in docs sent status 

							
							use integra