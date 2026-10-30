
WITH CustomerStats AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_paid) DESC) AS gender_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating
),
HighSpenders AS (
    SELECT
        c.c_customer_sk,
        cs.total_spent
    FROM CustomerStats cs
    JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE cs.total_spent > (
        SELECT AVG(total_spent) FROM CustomerStats
    )
),
StoreWebSummary AS (
    SELECT
        s.s_store_sk,
        SUM(ss.ss_net_paid) AS store_net_sales,
        SUM(ws.ws_net_paid) AS web_net_sales
    FROM store s
    LEFT JOIN store_sales ss ON s.s_store_sk = ss.ss_store_sk
    LEFT JOIN web_sales ws ON s.s_store_sk = ws.ws_ship_addr_sk
    GROUP BY s.s_store_sk
)
SELECT
    ss.s_store_sk,
    COALESCE(ss.store_net_sales, 0) AS store_sales,
    COALESCE(ss.web_net_sales, 0) AS web_sales,
    CASE
        WHEN COALESCE(ss.store_net_sales, 0) > COALESCE(ss.web_net_sales, 0) THEN 'Store'
        WHEN COALESCE(ss.web_net_sales, 0) > COALESCE(ss.store_net_sales, 0) THEN 'Web'
        ELSE 'Equal Sales'
    END AS dominant_sales_channel,
    COUNT(DISTINCT hs.c_customer_sk) AS high_spender_count
FROM StoreWebSummary ss
LEFT JOIN HighSpenders hs ON ss.s_store_sk = hs.c_customer_sk
GROUP BY ss.s_store_sk, ss.store_net_sales, ss.web_net_sales
ORDER BY ss.s_store_sk;
