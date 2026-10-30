
WITH RankedSales AS (
    SELECT
        ss_store_sk,
        ss_item_sk,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_net_paid) AS total_net_paid,
        RANK() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_net_paid) DESC) AS rank_within_store
    FROM store_sales
    GROUP BY ss_store_sk, ss_item_sk
),
TopStores AS (
    SELECT
        RANK() OVER (ORDER BY SUM(total_net_paid) DESC) AS store_rank,
        ss_store_sk
    FROM RankedSales
    GROUP BY ss_store_sk
    HAVING SUM(total_net_paid) > 50000
),
CustomerReturns AS (
    SELECT
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returned
    FROM store_returns
    GROUP BY sr_customer_sk
    HAVING SUM(sr_return_quantity) > 5
),
PromotionSummary AS (
    SELECT
        p.p_promo_id,
        SUM(ws_ext_sales_price) AS total_sales
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE p.p_start_date_sk <= 2452084 AND p.p_end_date_sk >= 2452084
    GROUP BY p.p_promo_id
)
SELECT 
    c.c_customer_id,
    ca.ca_city,
    cnt.store_rank,
    COALESCE(cr.total_returned, 0) AS returns,
    ps.total_sales
FROM customer c
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN TopStores cnt ON cnt.store_rank <= 5
LEFT JOIN CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
LEFT JOIN PromotionSummary ps ON ps.total_sales > 100000
WHERE 
    ca.ca_city IS NOT NULL
    AND cr.total_returned IS NULL OR cr.total_returned < 10
ORDER BY cnt.store_rank, c.c_customer_id;
