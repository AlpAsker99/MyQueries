SELECT 
ct.*
,lm.loanrecordid
,case when ct.[Transaction ID] like '%DSCR IO%' or rc_postclos.firstname is null then ' [Post Closer]' else rc_postclos.firstname + ' ' + rc_postclos.lastname end as postCloser
FROM CurrativeTasks ct
LEFT JOIN integra.dbo.loan_main lm ON lm.loanid = ct.[Loan ID]
LEFT JOIN  integra.dbo.loan_channelcontacts lcc_postclos
on lm.lenderdatabaseid = lcc_postclos.lenderdatabaseid 
and lm.loanrecordid = lcc_postclos.loanrecordid 
and lcc_postclos.associationid=35
	and lcc_postclos.entitycategoryid = (
	select max(lcc_postclos.entitycategoryid) from  integra.dbo.loan_channelcontacts lcc_postclos where loanrecordid = lm.loanrecordid and lcc_postclos.associationid=35)
left join  integra.dbo.rolodex_contacts rc_postclos
on rc_postclos.contactid = lcc_postclos.contactid
and rc_postclos.lenderdatabaseid = lcc_postclos.lenderdatabaseid

select * from  [dbo].[CurrativeTasks]

.USE [dm01]
GO

/****** Object:  Table [dbo].[CurrativeTasks]    Script Date: 11/30/2023 6:06:02 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[CurrativeTasks](
	ct.[ID] [int] IDENTITY(1,1) NOT NULL,
	ct.[Tenant] [varchar](50) NULL,
	ct.[Loan ID] [varchar](20) NULL,
	ct.[Transaction ID] [varchar](50) NULL,
	ct.[Status] [varchar](20) NULL,
	ct.[Last Action Date] [datetime] NULL,
	ct.[Finding Name] [varchar](500) NULL,
	ct.[Grade] [varchar](50) NULL,
	ct.[External Source] [varchar](50) NULL,
	ct.[Vendor Name] [float] NULL,
	ct.[Finding Code] [varchar](100) NULL,
	ct.[Compliance Test Status] [varchar](50) NULL,
	ct.[Queue] [varchar](50) NULL,
	ct.[Reviewer Comments] [varchar](8000) NULL,
	ct.[Comment from PC] [varchar](1000) NULL,
	ct.[Reponse date to DD] [datetime] NULL,
	ct.[Date Received] [datetime] NULL,
	ct.[DD finding] [varchar](500) NULL,
	ct.[How it was adressed] [varchar](3000) NULL,
	ct.[How it was resolved] [varchar](3000) NULL,
	ct.[Finding Type] [varchar](100) NULL,
	ct.[Exception Date] [datetime] NULL,
 CONSTRAINT [PK__Currativ__3214EC27BC3F232D] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [data]
) ON [data]
GO

