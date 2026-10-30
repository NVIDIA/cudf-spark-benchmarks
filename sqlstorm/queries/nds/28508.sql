
WITH RankedStores AS (
    SELECT 
        s_store_id,
        s_store_name,
        s_city,
        s_state,
        s_country,
        s_manager,
        ROW_NUMBER() OVER (PARTITION BY s_state ORDER BY s_number_employees DESC) AS rank
    FROM store
),
CustomerStatistics AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(ss.ss_ticket_number) AS total_purchases
    FROM customer c
    JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender
),
TopStores AS (
    SELECT 
        s.s_store_id, 
        s.s_store_name, 
        k.total_net_profit,
        k.total_purchases
    FROM RankedStores s
    JOIN CustomerStatistics k ON s.s_store_id = k.c_customer_id
    WHERE s.rank <= 5
)
SELECT 
    ts.s_store_id,
    ts.s_store_name,
    ts.total_net_profit,
    ts.total_purchases,
    CONCAT('Store: ', ts.s_store_name, ' | Total Net Profit: $', CAST(ts.total_net_profit AS DECIMAL(10, 2)), ' | Total Purchases: ', ts.total_purchases) AS store_summary
FROM TopStores ts
ORDER BY ts.total_net_profit DESC;
