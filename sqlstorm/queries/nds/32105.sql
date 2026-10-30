
WITH  sales_hierarchy AS (
    SELECT 
        c.c_customer_sk AS customer_sk,
        c.c_first_name AS first_name,
        c.c_last_name AS last_name,
        cd.cd_gender AS gender,
        cd.cd_marital_status AS marital_status,
        cd.cd_credit_rating AS credit_rating,
        SUM(ws.ws_net_profit) AS total_profit
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating
),
top_sales AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY gender ORDER BY total_profit DESC) AS rank
    FROM sales_hierarchy
)
SELECT 
    t.customer_sk,
    t.first_name,
    t.last_name,
    t.gender,
    t.marital_status,
    (SELECT COUNT(DISTINCT ws.ws_order_number) 
     FROM web_sales ws 
     WHERE ws.ws_bill_customer_sk = t.customer_sk) AS order_count,
    COALESCE(t.total_profit, 0) AS total_profit
FROM top_sales t
WHERE t.rank <= 10
ORDER BY total_profit DESC;
