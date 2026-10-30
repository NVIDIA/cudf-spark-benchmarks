
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ss.ss_sales_price) AS total_store_sales,
        SUM(ws.ws_sales_price) AS total_web_sales
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer_demographics cd
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cs.total_store_sales,
    cs.total_web_sales,
    (cs.total_store_sales + cs.total_web_sales) AS total_sales,
    COUNT(DISTINCT CASE WHEN cs.total_store_sales > 0 THEN 'Store Sale' END) AS num_store_transactions,
    COUNT(DISTINCT CASE WHEN cs.total_web_sales > 0 THEN 'Web Sale' END) AS num_web_transactions
FROM 
    CustomerSales cs
JOIN 
    customer c ON cs.c_customer_id = c.c_customer_id
JOIN 
    CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    cs.total_store_sales + cs.total_web_sales > 0
GROUP BY 
    c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, cs.total_store_sales, cs.total_web_sales
ORDER BY 
    total_sales DESC
LIMIT 50;
