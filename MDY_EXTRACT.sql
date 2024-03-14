
insert into test values ('02/30')
------================================------================================------================================------================================
--V1
select  left(select replace(   (trim( 'q w e r t y u i o p a s d f g h j k l z x c v b n m / . - '  FROM val)), ' ','')from test,2)+'/'
+right(replace(   trim( 'q w e r t y u i o p a s d f g h j k l z x c v b n m '  FROM val), ' ',''),2)+'/'+
cast(year(getdate())as varchar (100))
from test
select * from test

/*if we have '1one1' in our string TRIM wont delete the letters, so we need to put spaces after every character
to let TRIM do it's job.
*/
------================================------================================------================================------================================
--																	***V2***
select 
	case 
		when 
			left(left((replace((replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace
			(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(
			replace(replace(replace(replace(replace(replace(replace(
			(val),'q',''), 'w',''),'e',''),'r','')
			,'t',''),'y',''),'u',''),'i',''),'o',''),'p','')
			,'a',''),'s',''),'d',''),'f',''),'g',''),'h','')
			,'j',''),'k',''),'l',''),'z',''),'x',''),'c','')
			,'v',''),'b',''),'n',''),'m',''),'/',''),'.',''),'-','')
			,'[',''),']',''),'\',''),'`','')), ' ','')),2) 
		+
			right
			((replace((replace(replace(replace(replace(replace(replace(replace(replace(replace(replace
			(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(
			replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(
			(val),'q',''), 'w',''),'e',''),'r','')
			,'t',''),'y',''),'u',''),'i',''),'o',''),'p','')
			,'a',''),'s',''),'d',''),'f',''),'g',''),'h','')
			,'j',''),'k',''),'l',''),'z',''),'x',''),'c','')
			,'v',''),'b',''),'n',''),'m',''),'/',''),'.',''),'-','')
			,'[',''),']',''),'\',''),'`','')), ' ','')),2),1) !=''
		and 
			left(left((replace((replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace
			(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(
			replace(replace(replace(replace(replace(replace(replace(
			(val),'q',''), 'w',''),'e',''),'r','')
			,'t',''),'y',''),'u',''),'i',''),'o',''),'p','')
			,'a',''),'s',''),'d',''),'f',''),'g',''),'h','')
			,'j',''),'k',''),'l',''),'z',''),'x',''),'c','')
			,'v',''),'b',''),'n',''),'m',''),'/',''),'.',''),'-','')
			,'[',''),']',''),'\',''),'`','')), ' ','')),2) 
		+
			right((replace((replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace
			(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(
			replace(replace(replace(replace(replace(replace(replace(
			(val),'q',''), 'w',''),'e',''),'r','')
			,'t',''),'y',''),'u',''),'i',''),'o',''),'p','')
			,'a',''),'s',''),'d',''),'f',''),'g',''),'h','')
			,'j',''),'k',''),'l',''),'z',''),'x',''),'c','')
			,'v',''),'b',''),'n',''),'m',''),'/',''),'.',''),'-','')
			,'[',''),']',''),'\',''),'`','')), ' ','')),2),2) !>12
		and 
			right(left((replace((replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace
			(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(
			replace(replace(replace(replace(replace(replace(replace(
			(val),'q',''), 'w',''),'e',''),'r','')
			,'t',''),'y',''),'u',''),'i',''),'o',''),'p','')
			,'a',''),'s',''),'d',''),'f',''),'g',''),'h','')
			,'j',''),'k',''),'l',''),'z',''),'x',''),'c','')
			,'v',''),'b',''),'n',''),'m',''),'/',''),'.',''),'-','')
			,'[',''),']',''),'\',''),'`','')), ' ','')),2) 
		+
			right((replace((replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace
			(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(
			replace(replace(replace(replace(replace(replace(replace(
			(val),'q',''), 'w',''),'e',''),'r','')
			,'t',''),'y',''),'u',''),'i',''),'o',''),'p','')
			,'a',''),'s',''),'d',''),'f',''),'g',''),'h','')
			,'j',''),'k',''),'l',''),'z',''),'x',''),'c','')
			,'v',''),'b',''),'n',''),'m',''),'/',''),'.',''),'-','')
			,'[',''),']',''),'\',''),'`','')), ' ','')),2),2) !>31
		and 
			right(left((replace((replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace
			(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(
			replace(replace(replace(replace(replace(replace(replace(
			(val),'q',''), 'w',''),'e',''),'r','')
			,'t',''),'y',''),'u',''),'i',''),'o',''),'p','')
			,'a',''),'s',''),'d',''),'f',''),'g',''),'h','')
			,'j',''),'k',''),'l',''),'z',''),'x',''),'c','')
			,'v',''),'b',''),'n',''),'m',''),'/',''),'.',''),'-','')
			,'[',''),']',''),'\',''),'`','')), ' ','')),2) 
		+
			right((replace((replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace
			(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(
			replace(replace(replace(replace(replace(replace(replace(
			(val),'q',''), 'w',''),'e',''),'r','')
			,'t',''),'y',''),'u',''),'i',''),'o',''),'p','')
			,'a',''),'s',''),'d',''),'f',''),'g',''),'h','')
			,'j',''),'k',''),'l',''),'z',''),'x',''),'c','')
			,'v',''),'b',''),'n',''),'m',''),'/',''),'.',''),'-','')
			,'[',''),']',''),'\',''),'`','')), ' ','')),2),4) not in ('0230','0231')

		then 
			cast(  left((replace((replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace
			(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(
			replace(replace(replace(replace(replace(replace(replace(
			(val),'q',''), 'w',''),'e',''),'r','')
			,'t',''),'y',''),'u',''),'i',''),'o',''),'p','')
			,'a',''),'s',''),'d',''),'f',''),'g',''),'h','')
			,'j',''),'k',''),'l',''),'z',''),'x',''),'c','')
			,'v',''),'b',''),'n',''),'m',''),'/',''),'.',''),'-','')
			,'[',''),']',''),'\',''),'`','')), ' ','')),2)
		+'/'+
			right((replace((replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace
			(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(
			replace(replace(replace(replace(replace(replace(replace(
			(val),'q',''), 'w',''),'e',''),'r','')
			,'t',''),'y',''),'u',''),'i',''),'o',''),'p','')
			,'a',''),'s',''),'d',''),'f',''),'g',''),'h','')
			,'j',''),'k',''),'l',''),'z',''),'x',''),'c','')
			,'v',''),'b',''),'n',''),'m',''),'/',''),'.',''),'-','')
			,'[',''),']',''),'\',''),'`','')), ' ','')),2)
		+'/'
		+	(cast(year(getdate())as varchar(50))) as date)
	else ''
	end as [check]

from test

/*												***Notes***

			- in case a string doesn't contain a date, and a cell after our functional conversions
				is empty, the function will return '1900-01-01'. The reason for returning this date
				instead of blank, or null is that the function returns date data type and null for 
				date is '1900-01-01'.
			
			- date format check is implemented: mm !>12, dd!>31

			- incorrect february date check implemented (example: 02-30 etc). But the solution
				is temporary and has possible valnurabilities. If the next year you enter '02/29'
				it will crush the function. So, reliable solution is required.

				
*/
------================================------================================------================================------================================
select left(val, 2)+'/'+right(val, 2)+'/'+cast(year(getdate())as varchar (100))from test1 


select * from test where val like '[a-z]%'
select extract ([1-10] from val) from test
select substring(val, 1,10) from test
SELECT STUFF('SQL Tutorial', 1, 3, );

SELECT PATINDEX('%schools%', 'W3Schools.com');
SELECT SPACE(10);
SELECT SOUNDEX('expression'), Difference('1', 'juice');
SELECT CONCAT_WS('.', 'www', '/'+cast(year(getdate())as varchar(50)), 'com');
SELECT QUOTENAME('abcdef');
SELECT REPLICATE('SQL Tutorial', 5);
SELECT REVERSE('SQL Tutorial');
SELECT TRANSLATE('Monday', 'Monday', 'Sunday'); // Results in Sunday
alter table test 
alter column val varchar (100)
insert into test values (' 10 0 tu 5t vse')
--insert into test values ('must be locked before 10/0 6'), ('must be locked before 10 /0 7'), ('must be locked before 10 .0 8'), ('must be locked before 10 0 5')

create table test1 (val varchar (50))
insert into test1 values ('10.05'), ('1005'), ('10 05'),('10.05'), ('10 05.')

select replace(substring(val,3,1),'/','%%') from test1