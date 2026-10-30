
WITH SalesData AS (
    SELECT 
        ws_item_sk,
        COUNT(DISTINCT ws_order_number) AS order_count,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_net_paid,
        ROW_NUMBER() OVER (ORDER BY SUM(ws_net_paid) DESC) AS rank
    FROM web_sales 
    WHERE ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
    AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY ws_item_sk
),
StoreSalesData AS (
    SELECT 
        ss_item_sk,
        COUNT(DISTINCT ss_ticket_number) AS store_order_count,
        SUM(ss_quantity) AS store_total_quantity,
        SUM(ss_net_paid) AS store_total_net_paid
    FROM store_sales 
    WHERE ss_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY ss_item_sk
),
RankedSales AS (
    SELECT 
        sd.ws_item_sk,
        sd.order_count,
        sd.total_quantity,
        sd.total_net_paid,
        COALESCE(ss.store_order_count, 0) AS store_order_count,
        COALESCE(ss.store_total_quantity, 0) AS store_total_quantity,
        COALESCE(ss.store_total_net_paid, 0) AS store_total_net_paid,
        sd.rank
    FROM SalesData sd
    LEFT JOIN StoreSalesData ss ON sd.ws_item_sk = ss.ss_item_sk
)

SELECT 
    r.ws_item_sk,
    CASE 
        WHEN r.total_net_paid > 1000 THEN 'High Revenue'
        WHEN r.total_net_paid BETWEEN 500 AND 1000 THEN 'Medium Revenue'
        ELSE 'Low Revenue'
    END AS revenue_category,
    r.order_count + r.store_order_count AS total_orders,
    (r.store_total_net_paid + r.total_net_paid) / NULLIF((r.store_total_quantity + r.total_quantity), 0) AS avg_net_per_unit,
    CASE 
        WHEN r.rank IS NOT NULL THEN r.rank
        ELSE (SELECT COUNT(*) FROM RankedSales t WHERE t.total_net_paid > r.total_net_paid) + 1
    END AS dynamic_rank
FROM RankedSales r
WHERE r.total_quantity > 10 OR r.total_net_paid IS NULL
ORDER BY avg_net_per_unit DESC, total_orders ASC
LIMIT 10 OFFSET 5;

