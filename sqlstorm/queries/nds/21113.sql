
WITH CustomerStats AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        COALESCE(SUM(ss.ss_sales_price), 0) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS purchase_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY COALESCE(SUM(ss.ss_sales_price), 0) DESC) AS sales_rank
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        cd.cd_gender IS NOT NULL
        AND (cd.cd_purchase_estimate > 100 OR cd.cd_credit_rating IS NOT NULL)
    GROUP BY 
        c.c_customer_id, cd.cd_gender
),
HighSpenders AS (
    SELECT 
        c.c_customer_id,
        cs.total_sales
    FROM CustomerStats cs
    JOIN customer c ON cs.c_customer_id = c.c_customer_id
    WHERE cs.total_sales > (SELECT AVG(total_sales) FROM CustomerStats)
),
RecentPurchases AS (
    SELECT 
        c.c_customer_id,
        COUNT(ws.ws_order_number) AS recent_order_count
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE ws.ws_sold_date_sk > (SELECT MAX(d.d_date_sk) - 30 FROM date_dim d)
    GROUP BY c.c_customer_id
),
FinalReport AS (
    SELECT 
        hs.c_customer_id,
        hs.total_sales,
        rp.recent_order_count,
        CASE 
            WHEN hs.total_sales < 1000 THEN 'Low Spender'
            WHEN hs.total_sales BETWEEN 1000 AND 5000 THEN 'Mid Spender'
            ELSE 'High Spender'
        END AS spender_category
    FROM HighSpenders hs
    LEFT JOIN RecentPurchases rp ON hs.c_customer_id = rp.c_customer_id
)
SELECT 
    fr.c_customer_id,
    fr.total_sales,
    COALESCE(fr.recent_order_count, 0) AS recent_order_count,
    fr.spender_category,
    CASE 
        WHEN fr.spender_category = 'High Spender' AND fr.recent_order_count IS NULL THEN 'No Recent Orders'
        ELSE 'Active'
    END AS customer_status
FROM FinalReport fr
ORDER BY fr.total_sales DESC
LIMIT 100;
