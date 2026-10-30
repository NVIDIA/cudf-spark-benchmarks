
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        SUM(ws.ws_net_paid) AS total_spent,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_paid) DESC) AS rank_by_spending
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating
),
TopCustomers AS (
    SELECT 
        rc.c_customer_sk,
        rc.c_first_name,
        rc.c_last_name,
        rc.cd_gender,
        rc.cd_marital_status,
        rc.total_spent
    FROM RankedCustomers rc
    WHERE rc.rank_by_spending <= 5
),
StoreSalesStats AS (
    SELECT
        s.s_store_sk,
        SUM(ss.ss_net_profit) AS total_net_profit,
        AVG(ss.ss_sales_price) AS avg_sales_price,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
        COUNT(DISTINCT ss.ss_customer_sk) AS unique_customers
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE ss.ss_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) AND ss.ss_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY s.s_store_sk
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.cd_gender,
    s.s_store_sk,
    s.s_store_name,
    ss.total_net_profit,
    ss.avg_sales_price,
    ss.total_transactions,
    ss.unique_customers
FROM TopCustomers tc
CROSS JOIN store s
LEFT JOIN StoreSalesStats ss ON s.s_store_sk = ss.s_store_sk
WHERE ss.total_net_profit IS NOT NULL
ORDER BY tc.total_spent DESC, tc.c_first_name;
