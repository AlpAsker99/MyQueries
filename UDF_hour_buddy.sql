
													/* _____________________________________________________________
													|||				NAME OF OBJECT: "UDF_hour_buddy"				|||
													|||																|||
													|||			   TYPE: user-defined scalar function				|||
													|||																|||
													|||					AUTHOR: Aleskerov Nurlan					|||
													|||																|||
													|||				    CREATION DATE: 02/23/2024					|||
													|||																|||
													|||	DESCRIPTION: this function accepts 1 decimal data type 		|||
													|||				 argument as a number of hours and converts 	|||
													|||				 it into "days-hours-minutes" format			|||
													|||_____________________________________________________________|||
													*/




DECLARE @i DECIMAL(10,2)=24
DECLARE @main_select VARCHAR(MAX)=
				(

					SELECT

						CASE 
							WHEN @i>24

								--DAYS:
								THEN LEFT(@i/24, CHARINDEX('.',@i/24)-1)+'d '
			
								+ 
								--HOURS:
								LEFT(CAST('0.'+RIGHT(@i/24, LEN(@i/24)-CHARINDEX('.',@i/24))AS DECIMAL(10,2))*24,--this expression is number of hours (ex: 7.95)
									  CHARINDEX('.', CAST('0.'+RIGHT(@i/24, LEN(@i/24)-CHARINDEX('.',@i/24))AS DECIMAL(10,2))*24)-1)
								+ 'h '
		
								+
		
								--MINUTES:
								CAST(RIGHT(CAST('0.'+RIGHT(@i/24, LEN(@i/24)-CHARINDEX('.',@i/24))AS DECIMAL(10,2))*24
										,LEN(CAST('0.'+RIGHT(@i/24, LEN(@i/24)-CHARINDEX('.',@i/24))AS DECIMAL(10,2))*24)	  
										-
										CHARINDEX('.',CAST('0.'+RIGHT(@i/24, LEN(@i/24)-CHARINDEX('.',@i/24))AS DECIMAL(10,2))*24)
										)*6/10 AS VARCHAR(MAX))
								+'m'

								--NO DAYS:
								WHEN @i<24 
									THEN 
										CAST(LEFT(@i, CHARINDEX('.', @i)-1) AS VARCHAR (MAX) )
										+
										'h '
										+
										CAST(RIGHT(@i, LEN(@i)-CHARINDEX('.', @i))*6/10 AS VARCHAR(MAX))
										+ 'm'
								WHEN @i=24
									THEN CAST(CAST(@i AS int) AS VARCHAR (3))+'h'
									  END
				 )

				SELECT @main_select



--JUST IN CASE:
				--declare @days varchar(max)=
				-- ( select 
				--	CASE 
				--		WHEN substring(@main_select, patindex ('%[0-9][0-9]d%', @main_select),2)>0
				--		THEN left(@main_select, CHARINDEX('d', @main_select)) else null  end)
				
				--declare @hours varchar(max)=
				-- ( select 
				--	CASE 
				--		WHEN substring(@main_select, patindex ('%[0-9][0-9]h%', @main_select),2)>0
				--		THEN right(left(@main_select, CHARINDEX('h', @main_select))
				--				  ,len(left(@main_select, CHARINDEX('h', @main_select)))
				--				  -
				--				  charindex(' ', left(@main_select, CHARINDEX('h', @main_select))))
				--				  else null  end)						

				--declare @minutes varchar(max)=
				-- ( select 
				--	CASE 
				--		WHEN substring(@main_select, patindex ('%[0-9][0-9]m%', @main_select),2)>0
				--		THEN reverse(left(reverse(@main_select), CHARINDEX(' ', reverse(@main_select)))) else null  end)
