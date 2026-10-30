
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_purchases,
        SUM(ss.ss_sales_price) AS total_spent,
        AVG(ss.ss_sales_price) AS avg_spent,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ss.ss_sales_price) DESC) AS spend_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
TopCustomers AS (
    SELECT 
        cs.c_customer_sk, 
        cs.c_first_name, 
        cs.c_last_name, 
        cs.total_purchases,
        cs.total_spent,
        cs.avg_spent,
        cs.spend_rank
    FROM CustomerStats cs
    WHERE cs.total_purchases > 0
    AND cs.spend_rank <= 10
),
DateSummary AS (
    SELECT 
        d.d_date_id, 
        SUM(ws.ws_net_profit) AS total_profit
    FROM date_dim d
    LEFT JOIN web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY d.d_date_id
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_purchases,
    tc.total_spent,
    tc.avg_spent,
    ds.d_date_id,
    ds.total_profit
FROM TopCustomers tc
FULL OUTER JOIN DateSummary ds ON tc.total_spent > ds.total_profit
WHERE tc.total_spent IS NOT NULL
ORDER BY tc.total_spent DESC, ds.total_profit ASC;
