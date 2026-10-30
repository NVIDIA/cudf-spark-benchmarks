
WITH  sales_summary AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity, 
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS item_rank
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 20200301 AND 20200331
    GROUP BY ws_sold_date_sk, ws_item_sk
),
customer_stats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_ext_sales_price) AS total_spent
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
top_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_orders,
        cs.total_spent,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS customer_rank
    FROM customer_stats cs
    JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE cs.total_spent IS NOT NULL
),
monthly_sales AS (
    SELECT 
        d.d_year,
        SUM(ss.total_sales) AS monthly_sales
    FROM sales_summary ss
    JOIN date_dim d ON ss.ws_sold_date_sk = d.d_date_sk
    GROUP BY d.d_year
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_orders,
    tc.total_spent,
    ms.monthly_sales
FROM top_customers tc
LEFT JOIN monthly_sales ms ON tc.customer_rank = 1
WHERE tc.total_orders > 5
ORDER BY tc.total_spent DESC
LIMIT 10;
