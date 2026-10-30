
WITH customer_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_profit) AS avg_net_profit,
        cd.cd_gender AS gender,
        cd.cd_marital_status AS marital_status,
        cd.cd_education_status AS education_status
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2459355 AND 2459355 + 30 
    GROUP BY c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
top_customers AS (
    SELECT 
        c.c_customer_id AS customer_id,
        c.gender,
        c.marital_status,
        c.education_status,
        c.total_sales,
        c.order_count,
        c.avg_net_profit,
        RANK() OVER (ORDER BY c.total_sales DESC) AS sales_rank
    FROM customer_sales c
)
SELECT 
    tc.customer_id,
    tc.gender,
    tc.marital_status,
    tc.education_status,
    tc.total_sales,
    tc.order_count,
    tc.avg_net_profit
FROM top_customers tc
WHERE tc.sales_rank <= 10
ORDER BY tc.total_sales DESC;
