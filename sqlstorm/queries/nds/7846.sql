
WITH ranked_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_marital_status ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
customer_sales AS (
    SELECT 
        r.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        ranked_customers r
    JOIN 
        web_sales ws ON r.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        r.c_customer_sk
),
top_customers AS (
    SELECT 
        r.c_customer_sk,
        r.c_first_name,
        r.c_last_name,
        cs.total_sales,
        DENSE_RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        ranked_customers r
    JOIN 
        customer_sales cs ON r.c_customer_sk = cs.c_customer_sk
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    CASE 
        WHEN tc.sales_rank <= 10 THEN 'Top 10'
        WHEN tc.sales_rank <= 50 THEN 'Top 50'
        ELSE 'Others'
    END AS customer_category
FROM 
    top_customers tc
WHERE 
    tc.total_sales > 1000
ORDER BY 
    tc.total_sales DESC;
