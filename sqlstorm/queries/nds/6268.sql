
WITH ranked_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_purchases,
        SUM(ss.ss_sales_price) AS total_spent,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ss.ss_sales_price) DESC) AS rank_within_gender
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE
        c.c_birth_year BETWEEN 1970 AND 1990
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
top_customers AS (
    SELECT 
        rc.c_customer_sk,
        rc.c_first_name,
        rc.c_last_name,
        rc.cd_gender,
        rc.rank_within_gender,
        rc.total_spent
    FROM
        ranked_customers rc
    WHERE
        rc.rank_within_gender <= 5
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.cd_gender,
    tc.total_spent,
    COUNT(DISTINCT ws.ws_order_number) AS web_orders,
    AVG(ws.ws_net_profit) AS average_web_profit
FROM
    top_customers tc
LEFT JOIN
    web_sales ws ON tc.c_customer_sk = ws.ws_bill_customer_sk
GROUP BY
    tc.c_customer_sk, tc.c_first_name, tc.c_last_name, tc.cd_gender, tc.total_spent
ORDER BY
    total_spent DESC;
