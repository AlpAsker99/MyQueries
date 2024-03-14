--================================= SALES REPORT: BROKER & STATUS BY AE ===============================
WITH company_cte AS
	(
		SELECT 
			 bcrm.TITLE							[Name]
			,uts.UF_CRM_6225F0F2C2D28			[NMLS]
			,row_number() over (partition by uts.UF_CRM_6225F0F2C2D28 order by bcrm.TITLE)
												[Duplicate Counter]
			,uts.VALUE_ID						[KEY]
		FROM b_crm_company						bcrm
		LEFT JOIN b_uts_crm_company				uts
			ON uts.VALUE_ID=bcrm.ID
		WHERE cast(uts.UF_CRM_6225F0F2C2D28 as int)>1
		AND  uts.UF_CRM_6225F0F2C2D28 is not  null

		UNION ALL


		SELECT 
			 bcrm.TITLE							[Name]
			,uts.UF_CRM_6225F0F2C2D28			[NMLS]
			,1									[Duplicate Counter]
			,uts.VALUE_ID						[KEY]
		FROM b_crm_company						bcrm
		LEFT JOIN b_uts_crm_company				uts
			ON uts.VALUE_ID=bcrm.ID
		WHERE cast(uts.UF_CRM_6225F0F2C2D28 as int)<1
		OR uts.UF_CRM_6225F0F2C2D28 IS NULL
	) --INVESTEMENT ONLY COMPANIES

SELECT 
	  
	 c.[Name]									[Company Name]
--	 ,uts.TITLE									[Company Name]
	 ,UF_CRM_6225F0F2C2D28						[Company NMLS]
--	 ,ASSIGNED_BY_ID							[Account Executive]
	 ,usr.NAME+' '+usr.LAST_NAME				[Account Executive]
	
	,CASE 
		WHEN aer.TL_FullName IS NULL
		THEN 'No Team Defined'
		ELSE aer.TL_FullName				
		END AS									[Team]
--	 ,UF_TIME_RP_CHANGE							[Assigned to AE Date] the field is under construction 
--	 ,datediff(day, UF_TIME_RP_CHANGE, getdate())
--												[Days From Assigned to AE Date]
	 ,UF_Z_NO_OF_EMP_ACCOUNTS					[Number of Active Loan Officers]
	 ,UF_Z_CITY_COMPANY							[City]
--	 ,bcrm.UF_Z_STATE_ACCOUNTS					[State]
	 ,fn_state.VALUE							[State]
--	 ,UF_Z_ACCOUNT_STATUS						[Account type]
	 ,fn_acctype.VALUE							[Account type]
	 ,UF_Z_BROKER_PACKAGE_ACCOUNTS				[Broker Package / Branch Assignment Form]
	 ,datediff(day, UF_Z_BROKER_PACKAGE_ACCOUNTS, getdate())	
												[Days from Broker Package/Assignment Date]
--	 ,bcrm.UF_STATUS_STAGE						[Status (Per Bitrix)]
	 ,fn_status.VALUE							[Status (Per Bitrix)]
	 ,UF_Z_LAST_SUB_DATE_ACCOUNTS				[Last Submission Date]
--	 ,UF_Z_ANNUAL_PRO_ACCOUNTS					[Production (Volume) $] 
	
	,CASE 
		WHEN UF_Z_BROKER_PACKAGE_ACCOUNTS > dateadd(month, -12, getdate())
		THEN UF_Z_ANNUAL_PRO_ACCOUNTS
		ELSE null
		END AS									[Last 12M Volume ($)]

	 ,UF_VOLUME_12								[Production (Volume) Units]
	
	,CASE 
		WHEN aer.TL_FullName = 'Kaye Chapman'
		THEN 'KC'
		WHEN aer.TL_FullName = 'Mark Glaser'
		THEN 'MG'
		WHEN aer.TL_FullName = 'Max Slyusarchuk'
		THEN 'MS'
		WHEN aer.TL_FullName = 'Michael Pearson'
		THEN 'MP'
		WHEN aer.TL_FullName = 'Mike Majidian'
		THEN 'MM'
		WHEN aer.TL_FullName = 'Nadejda Smocvin'
		THEN 'NS'
		WHEN aer.TL_FullName = 'Xenia Voloch'
		THEN 'XV'
		ELSE 'Undefined'
		END AS [Team Lead Allias]
	
	,CASE 
		WHEN fn_status.VALUE IS NULL 
		THEN 'Undefined'
		ELSE fn_status.VALUE
		END AS									[Status (Per Bitrix)]
	
	,CASE 
		WHEN fn_status.VALUE = '0-4m submitting'
		THEN 1
		ELSE NULL
	    END AS [0-4m submitting]

	,CASE 
		WHEN fn_status.VALUE = '12m submitting'
		THEN 1
		ELSE NULL
		END AS [12m submitting]
	
	,CASE 
		WHEN fn_status.VALUE = '4-6m submitting'
		THEN 1
		ELSE NULL
		END AS [4-6m submitting]

	,CASE 
		WHEN fn_status.VALUE = '6-12m submitting'
		THEN 1
		ELSE NULL
		END AS [6-12m submitting]

	,CASE 
		WHEN fn_status.VALUE = 'Never submitting'
		THEN 1
		ELSE NULL
		END AS [Never submitting]
	
	,CASE 
		WHEN fn_status.VALUE = 'New'
		THEN 1
		ELSE NULL
		END AS [New]
	, row_number() over(partition by usr.NAME+' '+usr.LAST_NAME,fn_status.VALUE order by fn_status.VALUE )
	, fn_status.VALUE							[Status (Per Bitrix)]
	
	FROM b_crm_company							uts
												
LEFT JOIN b_uts_crm_company						bcrm
	ON bcrm.VALUE_ID=uts.ID						
												
LEFT JOIN b_user_field_enum						fn_status
	ON bcrm.UF_STATUS_STAGE = fn_status.ID		
												
LEFT JOIN b_user_field_enum						fn_state
	ON bcrm.UF_Z_STATE_ACCOUNTS = fn_state.ID	
												
LEFT JOIN b_user_field_enum						fn_acctype
	ON bcrm.UF_Z_ACCOUNT_STATUS = fn_acctype.ID	
												
LEFT JOIN b_user								usr
	ON usr.ID = uts.ASSIGNED_BY_ID

LEFT JOIN dm01.[dbo].[Roster_AE] aer
	ON aer.Display_Name=usr.NAME+' '+usr.LAST_NAME

INNER JOIN company_cte 							c
	ON c.[KEY]=uts.ID	
	AND [Duplicate Counter]=1

WHERE usr.NAME+' '+usr.LAST_NAME!='Yana Moroz'