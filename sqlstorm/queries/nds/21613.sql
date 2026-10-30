
WITH RankedSales AS (
    SELECT 
        ws_item_sk, 
        ws_order_number, 
        ws_sales_price, 
        ws_net_profit, 
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS rn
    FROM web_sales
    WHERE ws_sold_date_sk IN (
        SELECT d_date_sk 
        FROM date_dim 
        WHERE d_year = 2023 AND d_month_seq BETWEEN 1 AND 12
    )
),
StoreSalesSummary AS (
    SELECT 
        ss_item_sk,
        SUM(ss_net_profit) AS total_store_profit,
        COUNT(DISTINCT ss_store_sk) AS store_count
    FROM store_sales
    GROUP BY ss_item_sk
),
ItemPromotions AS (
    SELECT 
        ws_item_sk,
        COUNT(DISTINCT ws_promo_sk) AS promo_count
    FROM web_sales 
    WHERE ws_net_paid > 100
    GROUP BY ws_item_sk
)
SELECT 
    ca.ca_address_id, 
    ca.ca_city, 
    ca.ca_state, 
    COALESCE(ranked.ws_net_profit, 0) AS max_web_profit,
    COALESCE(store.total_store_profit, 0) AS total_store_profit,
    COALESCE(promos.promo_count, 0) AS total_promotions
FROM customer_address ca 
LEFT JOIN RankedSales ranked ON ranked.rn = 1 
LEFT JOIN StoreSalesSummary store ON ranked.ws_item_sk = store.ss_item_sk
LEFT JOIN ItemPromotions promos ON ranked.ws_item_sk = promos.ws_item_sk
WHERE ca.ca_state IS NOT NULL
AND (ca.ca_city = 'New York' OR ca.ca_city IS NULL)
AND (SELECT COUNT(*) FROM customer c WHERE c.c_current_addr_sk = ca.ca_address_sk AND c.c_birth_month = 0) > 0
ORDER BY max_web_profit DESC, total_store_profit ASC
LIMIT 10;
