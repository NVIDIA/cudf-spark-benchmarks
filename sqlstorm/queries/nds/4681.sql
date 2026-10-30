
WITH CustomerSales AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ss.ss_net_paid), 0) AS total_store_sales,
        COALESCE(SUM(ws.ws_net_paid), 0) AS total_web_sales,
        CASE 
            WHEN COALESCE(SUM(ss.ss_net_paid), 0) > COALESCE(SUM(ws.ws_net_paid), 0) THEN 'Store'
            WHEN COALESCE(SUM(ss.ss_net_paid), 0) < COALESCE(SUM(ws.ws_net_paid), 0) THEN 'Web'
            ELSE 'Equal'
        END AS preferred_channel
    FROM customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_store_sales,
        cs.total_web_sales,
        cs.preferred_channel,
        RANK() OVER (ORDER BY (cs.total_store_sales + cs.total_web_sales) DESC) as sales_rank
    FROM CustomerSales cs
    JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
)
SELECT
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_store_sales,
    tc.total_web_sales,
    tc.preferred_channel,
    COALESCE(hd.hd_buy_potential, 'Unknown') AS buy_potential,
    CASE 
        WHEN tc.preferred_channel = 'Store' AND hd.hd_buy_potential = 'High' THEN 'Target for promos'
        WHEN tc.preferred_channel = 'Web' AND hd.hd_buy_potential = 'Medium' THEN 'Consider upselling'
        ELSE 'Regular' 
    END AS marketing_strategy
FROM TopCustomers tc
LEFT JOIN household_demographics hd ON tc.c_customer_sk = hd.hd_demo_sk
WHERE tc.sales_rank <= 10
ORDER BY tc.total_store_sales + tc.total_web_sales DESC;
