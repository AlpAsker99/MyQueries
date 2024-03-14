
create procedure proc2
(@name varchar(50), @counter int output)
as
set @counter=
	(
	select count(FirstName) 
	from [Person].[Person]
	Where FirstName=@name
	)

	declare @counter int;
	exec proc2 'Ken', @counter output
	select @counter

create procedure return_proc1
as
begin
return select count(FirstName) 
		from[Person].[Person]
end

declare @return_val int
exec @return_val=return_proc1
select @return_val
