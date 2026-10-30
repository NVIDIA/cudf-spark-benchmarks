
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ss.ss_net_paid_inc_tax) AS total_store_sales,
        SUM(ws.ws_net_paid_inc_tax) AS total_web_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_transactions,
        COUNT(DISTINCT ws.ws_order_number) AS web_transactions
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        c.c_customer_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk, 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating
    FROM 
        customer_demographics cd
    INNER JOIN 
        CustomerSales cs ON cs.c_customer_sk = cd.cd_demo_sk
)
SELECT 
    cs.c_customer_sk,
    cs.total_store_sales,
    cs.total_web_sales,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_credit_rating
FROM 
    CustomerSales cs
JOIN 
    CustomerDemographics cd ON cs.c_customer_sk = cd.cd_demo_sk
WHERE 
    cs.total_store_sales > 10000 
    OR cs.total_web_sales > 10000
ORDER BY 
    total_store_sales DESC, total_web_sales DESC
LIMIT 100;
