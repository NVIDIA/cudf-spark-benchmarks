
WITH ranked_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        COUNT(DISTINCT wr.wr_order_number) AS return_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
customer_metrics AS (
    SELECT 
        *,
        CASE 
            WHEN total_sales > 1000 THEN 'High Value'
            WHEN total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_segment
    FROM 
        ranked_customers
)
SELECT 
    cm.c_first_name, 
    cm.c_last_name, 
    cm.cd_gender, 
    cm.cd_marital_status, 
    cm.customer_segment, 
    cm.total_sales, 
    cm.order_count, 
    cm.return_count
FROM 
    customer_metrics cm
WHERE 
    cm.return_count <= 1
ORDER BY 
    cm.total_sales DESC
LIMIT 
    100;
