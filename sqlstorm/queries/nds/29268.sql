
WITH CustomerData AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        c.c_email_address,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd_dep_count,
        cd_dep_employed_count,
        cd_dep_college_count,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
PurchaseSummary AS (
    SELECT 
        CASE 
            WHEN ws_bill_customer_sk IS NOT NULL THEN 'Web'
            WHEN cs_bill_customer_sk IS NOT NULL THEN 'Catalog'
            WHEN ss_customer_sk IS NOT NULL THEN 'Store'
        END AS purchase_channel,
        SUM(COALESCE(ws_net_paid, cs_net_paid, ss_net_paid)) AS total_amount,
        COUNT(*) AS purchase_count
    FROM 
        web_sales ws 
    FULL OUTER JOIN 
        catalog_sales cs ON ws.ws_bill_customer_sk = cs.cs_bill_customer_sk 
    FULL OUTER JOIN 
        store_sales ss ON ws.ws_bill_customer_sk = ss.ss_customer_sk
    GROUP BY 
        purchase_channel
)
SELECT 
    cd.full_name,
    cd.c_email_address,
    cd.cd_gender,
    cd.cd_marital_status,
    ps.purchase_channel,
    ps.total_amount,
    ps.purchase_count
FROM 
    CustomerData cd
LEFT JOIN 
    PurchaseSummary ps ON ps.purchase_channel = CASE 
        WHEN cd.c_email_address IS NOT NULL THEN 'Web'
        WHEN cd.c_email_address IS NOT NULL THEN 'Catalog'
        ELSE 'Store'
    END
WHERE 
    cd.cd_purchase_estimate > 1000
ORDER BY 
    ps.total_amount DESC, cd.full_name;
