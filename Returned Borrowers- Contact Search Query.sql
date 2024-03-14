------------------------------------------------------------------------------------------------
--use dm01 
--select * from Roster_AE 
--where Region like '%Retail%'
--and First_Name+' '+Last_name like '%Alex%Mikhalenia%'
--order by Last_Name

 
------------------------------------------------------------------------------------------------
DECLARE @ContName varchar(100) = 'RAUL GARCIA';
 
with managers as (
    select
        c.UF_FULL_NAME
        , concat(cc.NAME, ' ', cc.LAST_NAME) as ContactName
        , case 
            WHEN we.VALUE is not NULL 
                THEN IIF(LEFT(we.VALUE, 11) = 'duplicated_', SUBSTRING(we.VALUE, 12, LEN(we.VALUE)), 
                        IIF(LEFT(we.VALUE, 12) = 'duplicated2_', SUBSTRING(we.VALUE, 13, LEN(we.VALUE)), 
                            IIF(LEFT(we.VALUE, 10) = 'duplicate_', SUBSTRING(we.VALUE, 11, LEN(we.VALUE)), 
                            we.VALUE)
                        )
                    ) 
            WHEN oe.VALUE is not NULL THEN oe.VALUE
            WHEN he.VALUE is not NULL THEN he.VALUE
            END as Email
        , cc.COMPANY_ID
        , c.UF_Z_CONTACT_TITLE_CONTACT
        , title.VALUE as Title
    from [bi-02].crm.dbo.b_uts_crm_contact c
    LEFT OUTER JOIN [bi-02].crm.dbo.b_crm_contact cc 
        ON c.VALUE_ID = cc.ID
    LEFT OUTER JOIN [bi-02].crm.dbo.b_user_field_enum title 
        on title.ID = c.UF_Z_CONTACT_TITLE_CONTACT
    LEFT OUTER JOIN [bi-02].crm.dbo.b_crm_field_multi we 
        on we.ELEMENT_ID = c.VALUE_ID and we.ENTITY_ID = 'CONTACT' and we.TYPE_ID = 'EMAIL' and we.VALUE_TYPE = 'WORK'
    LEFT OUTER JOIN [bi-02].crm.dbo.b_crm_field_multi oe 
        on oe.ELEMENT_ID = c.VALUE_ID and oe.ENTITY_ID = 'CONTACT' and oe.TYPE_ID = 'EMAIL' and oe.VALUE_TYPE = 'OTHER'
    LEFT OUTER JOIN [bi-02].crm.dbo.b_crm_field_multi he 
        on he.ELEMENT_ID = c.VALUE_ID and he.ENTITY_ID = 'CONTACT' and he.TYPE_ID = 'EMAIL' and he.VALUE_TYPE = 'HOME'
    where c.UF_Z_CONTACT_TITLE_CONTACT in (477, 117729, 481)
)
 
select
    --c.VALUE_ID
  --  , c.UF_FULL_NAME
     concat(cc.NAME, ' ', cc.LAST_NAME) as ContactName
    --, c.UF_Z_CONTACT_TITLE_CONTACT
    --, title.VALUE as Title
    , case 
        WHEN we.VALUE is not NULL 
            THEN IIF(LEFT(we.VALUE, 11) = 'duplicated_', SUBSTRING(we.VALUE, 12, LEN(we.VALUE)), 
                    IIF(LEFT(we.VALUE, 12) = 'duplicated2_', SUBSTRING(we.VALUE, 13, LEN(we.VALUE)), 
                        IIF(LEFT(we.VALUE, 10) = 'duplicate_', SUBSTRING(we.VALUE, 11, LEN(we.VALUE)), 
                            we.VALUE)
                    )
                ) 
        ELSE CASE 
                WHEN oe.VALUE is not NULL THEN oe.VALUE
                ELSE CASE
                        WHEN he.VALUE is not NULL THEN he.VALUE
                        END
                END
        END as Email
    --, cc.ASSIGNED_BY_ID
    , uae.EMAIL AE_Email
    , concat(uae.NAME, ' ', uae.LAST_NAME) AE_Name
    --, ui.UF_DEPARTMENT_NAME Dept
    --, cc.COMPANY_ID
    --, c.UF_COMPANY_TITLE_IT
    , a.UF_COMPANY_TITLE_IT
	 , 'Wholesale'
    --, a.UF_Z_OW_BRANCH_MANAGER_ACCOUNTS
    --, co.UF_FULL_NAME as OwnerFullName
    , concat(cco.NAME, ' ', cco.LAST_NAME) as OwnerName0
    , case 
        WHEN owe.VALUE is not NULL THEN IIF(LEFT(owe.VALUE, 11) = 'duplicated_', SUBSTRING(owe.VALUE, 12, LEN(owe.VALUE)), owe.VALUE) 
        ELSE CASE
                WHEN ooe.VALUE is not NULL THEN ooe.VALUE
                ELSE CASE
                        WHEN ohe.VALUE is not NULL THEN ohe.VALUE
                        END
                END
        END as OEmail
    --, co2.ContactName as ManCName
    --, co2.UF_FULL_NAME as ManName
    --, co2.Email ManEmail
    --, co2.Title ManTitle
from [bi-02].crm.dbo.b_uts_crm_contact c
LEFT OUTER JOIN [bi-02].crm.dbo.b_crm_contact cc ON c.VALUE_ID = cc.ID
LEFT OUTER JOIN [bi-02].crm.dbo.b_user_field_enum title on title.ID = c.UF_Z_CONTACT_TITLE_CONTACT
LEFT OUTER JOIN [bi-02].crm.dbo.b_crm_field_multi we on we.ELEMENT_ID = c.VALUE_ID and we.ENTITY_ID = 'CONTACT' and we.TYPE_ID = 'EMAIL' and we.VALUE_TYPE = 'WORK'
LEFT OUTER JOIN [bi-02].crm.dbo.b_crm_field_multi oe on oe.ELEMENT_ID = c.VALUE_ID and oe.ENTITY_ID = 'CONTACT' and oe.TYPE_ID = 'EMAIL' and oe.VALUE_TYPE = 'OTHER'
LEFT OUTER JOIN [bi-02].crm.dbo.b_crm_field_multi he on he.ELEMENT_ID = c.VALUE_ID and he.ENTITY_ID = 'CONTACT' and he.TYPE_ID = 'EMAIL' and he.VALUE_TYPE = 'HOME'
LEFT OUTER JOIN [bi-02].crm.dbo.b_user uae on uae.ID = cc.ASSIGNED_BY_ID
LEFT OUTER JOIN [bi-02].crm.dbo.b_user_index ui on ui.USER_ID = uae.ID
LEFT OUTER JOIN [bi-02].crm.dbo.b_uts_crm_company a on a.VALUE_ID = cc.COMPANY_ID
LEFT OUTER JOIN [bi-02].crm.dbo.b_uts_crm_contact co ON co.VALUE_ID = a.UF_Z_OW_BRANCH_MANAGER_ACCOUNTS
LEFT OUTER JOIN [bi-02].crm.dbo.b_crm_contact cco ON cco.ID = a.UF_Z_OW_BRANCH_MANAGER_ACCOUNTS
LEFT OUTER JOIN [bi-02].crm.dbo.b_crm_field_multi owe on owe.ELEMENT_ID = co.VALUE_ID and owe.ENTITY_ID = 'CONTACT' and owe.TYPE_ID = 'EMAIL' and owe.VALUE_TYPE = 'WORK'
LEFT OUTER JOIN [bi-02].crm.dbo.b_crm_field_multi ooe on ooe.ELEMENT_ID = co.VALUE_ID and ooe.ENTITY_ID = 'CONTACT' and ooe.TYPE_ID = 'EMAIL' and ooe.VALUE_TYPE = 'OTHER'
LEFT OUTER JOIN [bi-02].crm.dbo.b_crm_field_multi ohe on ohe.ELEMENT_ID = co.VALUE_ID and ohe.ENTITY_ID = 'CONTACT' and ohe.TYPE_ID = 'EMAIL' and ohe.VALUE_TYPE = 'HOME'
LEFT OUTER JOIN managers co2 on co2.COMPANY_ID = cc.COMPANY_ID
 
--where c.UF_FULL_NAME = @ContName or concat(cc.NAME, ' ', cc.LAST_NAME) = @ContName
--where c.UF_FULL_NAME like '%Lance Monson%'
--where cc.Name like '%Oprea%'-- and cc.LAST_NAME like '%Nguyen%'
--where cc.LAST_NAME like '%Contact%'
where a.UF_COMPANY_TITLE_IT like '%Tower Home Loans%'
order by c.VALUE_ID
