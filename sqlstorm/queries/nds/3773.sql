WITH SalesSummary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_net_profit) AS total_net_profit
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2451604 AND 2451644 
    GROUP BY ws_item_sk
),
StoreSalesSummary AS (
    SELECT 
        ss_item_sk,
        SUM(ss_quantity) AS total_quantity_sold_store,
        SUM(ss_net_profit) AS total_net_profit_store
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN 2451604 AND 2451644 
    GROUP BY ss_item_sk
),
CombinedSales AS (
    SELECT 
        COALESCE(w.ws_item_sk, s.ss_item_sk) AS item_sk,
        COALESCE(w.total_quantity_sold, 0) AS total_web_sales,
        COALESCE(s.total_quantity_sold_store, 0) AS total_store_sales,
        COALESCE(w.total_net_profit, 0) + COALESCE(s.total_net_profit_store, 0) AS total_net_profit_combined
    FROM SalesSummary w
    FULL OUTER JOIN StoreSalesSummary s ON w.ws_item_sk = s.ss_item_sk
)
SELECT 
    i.i_item_id,
    i.i_product_name,
    cs.total_web_sales,
    cs.total_store_sales,
    cs.total_net_profit_combined,
    CASE 
        WHEN cs.total_net_profit_combined > 10000 THEN 'High Performer'
        WHEN cs.total_net_profit_combined BETWEEN 5000 AND 10000 THEN 'Moderate Performer'
        ELSE 'Low Performer'
    END AS performance_category
FROM item i
JOIN CombinedSales cs ON i.i_item_sk = cs.item_sk
WHERE (cs.total_web_sales + cs.total_store_sales) > 0
ORDER BY total_net_profit_combined DESC
LIMIT 10;