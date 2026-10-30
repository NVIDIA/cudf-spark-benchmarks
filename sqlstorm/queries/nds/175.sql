
WITH RecentSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_net_paid
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim)
    GROUP BY 
        ws_item_sk
),
StoreSalesSummary AS (
    SELECT 
        ss_item_sk,
        COUNT(DISTINCT ss_store_sk) AS unique_stores,
        SUM(ss_net_paid) AS total_store_net_paid
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim)
    GROUP BY 
        ss_item_sk
),
CombinedSales AS (
    SELECT 
        r.ws_item_sk,
        COALESCE(r.total_quantity, 0) AS web_quantity,
        COALESCE(s.unique_stores, 0) AS store_unique_stores,
        COALESCE(s.total_store_net_paid, 0) AS store_net_paid,
        r.total_net_paid AS web_net_paid
    FROM 
        RecentSales r
    FULL OUTER JOIN 
        StoreSalesSummary s ON r.ws_item_sk = s.ss_item_sk
)
SELECT 
    i.i_item_id,
    i.i_product_name,
    cs.web_quantity,
    cs.store_unique_stores,
    cs.store_net_paid,
    cs.web_net_paid,
    (cs.web_net_paid - cs.store_net_paid) AS price_difference,
    CASE 
        WHEN cs.store_net_paid IS NULL OR cs.web_net_paid IS NULL THEN 'INCOMPLETE DATA'
        WHEN cs.web_net_paid > cs.store_net_paid THEN 'Web Sales Higher'
        WHEN cs.web_net_paid < cs.store_net_paid THEN 'Store Sales Higher'
        ELSE 'Equal Sales'
    END AS sales_comparison
FROM 
    item i
LEFT JOIN 
    CombinedSales cs ON i.i_item_sk = cs.ws_item_sk
WHERE 
    i.i_current_price > 10.00
ORDER BY 
    price_difference DESC
LIMIT 100;
