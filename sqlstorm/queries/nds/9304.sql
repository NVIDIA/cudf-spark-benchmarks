
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        SUM(ws.ws_ext_sales_price) AS total_web_sales
    FROM 
        customer c 
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
customer_details AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        c.c_customer_sk
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_comparison AS (
    SELECT 
        cs.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cs.total_store_sales,
        cs.total_web_sales,
        COALESCE(cs.total_store_sales, 0) - COALESCE(cs.total_web_sales, 0) AS sales_difference
    FROM 
        customer_sales cs
    JOIN 
        customer_details cd ON cs.c_customer_sk = cd.c_customer_sk
)
SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    COUNT(*) AS customer_count,
    AVG(sc.sales_difference) AS avg_sales_difference,
    MAX(sc.total_store_sales) AS max_store_sales,
    MAX(sc.total_web_sales) AS max_web_sales
FROM 
    sales_comparison sc
JOIN 
    customer_details cd ON sc.c_customer_sk = cd.c_customer_sk
GROUP BY 
    cd.cd_gender, cd.cd_marital_status
ORDER BY 
    avg_sales_difference DESC, customer_count DESC
LIMIT 10;
