
WITH ranked_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate IS NOT NULL
), 
customer_sales AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
), 
top_sales AS (
    SELECT 
        cs.customer_sk, 
        cs.total_sales,
        rc.c_customer_id,
        rc.cd_gender,
        rc.cd_marital_status,
        rc.cd_credit_rating
    FROM 
        customer_sales cs
    JOIN 
        ranked_customers rc ON cs.customer_sk = rc.c_customer_sk
    WHERE 
        rc.rank <= 10
)
SELECT 
    t.cd_gender,
    COUNT(*) AS customer_count,
    AVG(t.total_sales) AS avg_sales,
    SUM(CASE WHEN t.cd_marital_status = 'M' THEN 1 ELSE 0 END) AS married_count,
    COUNT(DISTINCT t.c_customer_id) FILTER (WHERE t.cd_credit_rating = 'Good') AS good_credit_customers
FROM 
    top_sales t
GROUP BY 
    t.cd_gender
ORDER BY 
    customer_count DESC
LIMIT 5;
