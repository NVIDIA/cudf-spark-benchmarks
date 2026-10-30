
WITH CustomerSales AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        MAX(ws.ws_sold_date_sk) AS last_order_date
    FROM customer AS c
    JOIN web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE c.c_birth_year BETWEEN 1980 AND 1995
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_sales,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM CustomerSales AS cs
    JOIN customer AS c ON cs.c_customer_sk = c.c_customer_sk
    WHERE cs.order_count > 5
),
ShipModes AS (
    SELECT 
        sm.sm_ship_mode_sk,
        sm.sm_type,
        COUNT(*) AS mode_usage
    FROM store_sales AS ss
    JOIN ship_mode AS sm ON ss.ss_promo_sk = sm.sm_ship_mode_sk
    GROUP BY sm.sm_ship_mode_sk, sm.sm_type
)
SELECT
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    ss.ss_sold_date_sk,
    ss.ss_net_profit,
    COALESCE(sm.sm_type, 'Unknown') AS shipping_method,
    ROW_NUMBER() OVER (PARTITION BY sm.sm_type ORDER BY tc.total_sales DESC) AS shipping_rank
FROM TopCustomers AS tc
LEFT JOIN store_sales AS ss ON tc.c_customer_sk = ss.ss_customer_sk
LEFT JOIN ShipModes AS sm ON ss.ss_store_sk = sm.mode_usage
WHERE (ss.ss_net_profit IS NOT NULL AND ss.ss_net_profit > 0)
  OR (ss.ss_net_profit IS NULL AND tc.total_sales >= 500)
ORDER BY tc.total_sales DESC, ss.ss_sold_date_sk DESC;
