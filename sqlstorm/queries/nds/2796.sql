
WITH CustomerReturns AS (
    SELECT 
        c.c_customer_id,
        SUM(COALESCE(sr_return_quantity, 0) + COALESCE(cr_return_quantity, 0) + COALESCE(wr_return_quantity, 0)) AS total_returns,
        COUNT(DISTINCT sr_ticket_number) AS store_return_count,
        COUNT(DISTINCT cr_order_number) AS catalog_return_count,
        COUNT(DISTINCT wr_order_number) AS web_return_count
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN 
        catalog_returns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
    LEFT JOIN 
        web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
    GROUP BY 
        c.c_customer_id
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT c.c_customer_id) AS customer_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
)
SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    SUM(cr.total_returns) AS total_customer_returns,
    AVG(cd.customer_count) AS avg_customers_per_demo
FROM 
    CustomerReturns cr
JOIN 
    customer c ON c.c_customer_id = cr.c_customer_id
JOIN 
    CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    cr.total_returns > 0
GROUP BY 
    cd.cd_gender, cd.cd_marital_status
ORDER BY 
    total_customer_returns DESC
LIMIT 10;
