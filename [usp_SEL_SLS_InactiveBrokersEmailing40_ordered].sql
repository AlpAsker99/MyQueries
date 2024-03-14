CREATE PROC usp_SEL_SLS_InactiveBrokersEmailing40_ordered AS
BEGIN
	
	WITH re_cte
	AS (
		SELECT lcc.lenderdatabaseid
			, lcc.loanrecordid
			, lcc.associationid
			, re.entityid
			, re.name
			, ROW_NUMBER() OVER (
				PARTITION BY lcc.lenderdatabaseid
				, lcc.loanrecordid
				, lcc.associationid ORDER BY re.entityid
				) AS duplicate
		FROM integra.dbo.loan_channelcontacts lcc
		INNER JOIN integra.dbo.rolodex_entity re
			ON lcc.lenderdatabaseid = re.lenderdatabaseid
				AND re.entityid = lcc.entityid
		)
		, rc_cte
	as (
		SELECT lcc.lenderdatabaseid
			, lcc.loanrecordid
			, lcc.associationid
			, rc.firstname
			, rc.lastname
			, rc.emailaddress
			, raem.TL_Initials
			, ROW_NUMBER() over (partition by lcc.lenderdatabaseid, lcc.loanrecordid, lcc.associationid 
				order by rc.contactid) as duplicate
		FROM integra.dbo.loan_channelcontacts lcc
		INNER JOIN integra.dbo.rolodex_contacts rc
			ON lcc.lenderdatabaseid = rc.lenderdatabaseid
				AND rc.contactid = lcc.contactid
		LEFT JOIN dm01.dbo.Roster_AE raem
			ON raem.contactid = rc.contactid
		)
		, orig_cte
	AS (
		SELECT lm.loanrecordid
			--, lm.loanid
			, lpc.submissiondate
			, CASE 
				WHEN re_orig.entityid IS NULL
					THEN re_corr.entityid
				ELSE re_orig.entityid
				END AS OrigEntityid
			, CASE 
				WHEN re_orig.name IS NULL
					THEN re_corr.name
				ELSE re_orig.name
				END AS OrigName
			, CONCAT (
				rc_ae.firstname
				, ' '
				, rc_ae.lastname
				) AS [Account Executive]
			, rc_ae.emailaddress
			, rc_ae.TL_Initials
			, CASE 
				WHEN rc_orig.firstname + ' ' + rc_orig.lastname IS NULL
					THEN rc_corr.firstname + ' ' + rc_corr.lastname
				ELSE rc_orig.firstname + ' ' + rc_orig.lastname
				END AS [Originator Name]
			, coalesce(rc_orig.emailaddress, rc_corr.emailaddress) as OrigEmail
		FROM integra.dbo.loan_main lm
		INNER JOIN integra.dbo.loan_postclosing lpc
			ON lm.loanrecordid = lpc.loanrecordid
				AND lm.lenderdatabaseid = lpc.lenderdatabaseid
		LEFT JOIN re_cte re_orig
			ON re_orig.loanrecordid = lm.loanrecordid
				AND re_orig.lenderdatabaseid = lm.lenderdatabaseid
				and re_orig.associationid IN (1, 22)
				and re_orig.duplicate = 1
		LEFT JOIN re_cte re_corr
			ON re_corr.loanrecordid = lm.loanrecordid
				AND re_corr.lenderdatabaseid = lm.lenderdatabaseid
				AND re_corr.associationid = 105
				AND re_corr.duplicate = 1
		LEFT JOIN rc_cte rc_orig
			ON rc_orig.loanrecordid = lm.loanrecordid
				AND rc_orig.lenderdatabaseid = lm.lenderdatabaseid
				AND rc_orig.associationid IN (1, 22)
				AND rc_orig.duplicate = 1
		LEFT JOIN rc_cte rc_corr
			ON rc_corr.loanrecordid = lm.loanrecordid
				AND rc_corr.lenderdatabaseid = lm.lenderdatabaseid
				AND rc_corr.associationid = 105
				AND rc_corr.duplicate = 1
		LEFT JOIN rc_cte rc_ae
			ON rc_ae.loanrecordid = lm.loanrecordid
				AND rc_ae.lenderdatabaseid = lm.lenderdatabaseid
				AND rc_ae.associationid = 102
				AND rc_ae.duplicate = 1
		WHERE lm.loanrecordid NOT IN (
				SELECT loanrecordid
				FROM dm01.dbo.integra_test_loans
				)
			AND lpc.submissiondate != '1800-01-01 00:00:00.000'
			AND lpc.submissiondate >= DATEADD(DAY, - 280, GETDATE())
			AND (re_orig.entityid IS NOT NULL
				OR re_corr.entityid IS NOT NULL)
		)
		, group_cte
	AS (
		SELECT o.OrigName
			, o.[Originator Name]
			, o.OrigEmail as [Originator Email]
			, count(o.loanrecordid) over (partition by o.OrigEntityid) 
				AS orig_count
			, max(o.submissiondate) over (partition by o.OrigEntityid) 
				AS last_submit
			, o.[Account Executive]
			, o.emailaddress as [AE Email]
			, o.TL_Initials as [Team]
			, ROW_NUMBER() over (partition by o.OrigEntityid 
				order by o.submissiondate desc) as row_entry
		FROM orig_cte o
		)
	
	SELECT 
	      --ROW_NUMBER() OVER(ORDER BY re_orig.entityid ) AS [ID],
		  g.Team
		, g.[Account Executive]
		, g.[AE Email]
		, g.OrigName AS [Originator Company]
		, g.[Originator Name]
		, g.[Originator Email]
		, g.orig_count AS [Submitted Loans]
		, cast(g.last_submit as date) AS [Last Submission Date]
		, DATEDIFF(day, g.last_submit, GETDATE()) AS [Days since Last Submission]
		--, SYSDATETIME() as [Date Inserted] 

	FROM group_cte g
	WHERE g.orig_count >= 8
		AND g.row_entry = 1
		AND DATEDIFF(day, g.last_submit, GETDATE()) >= 40
	ORDER BY [Team], [Account Executive], [Days since Last Submission] DESC


END