
WITH RankedSales AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS rank
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk IN (
        SELECT d.d_date_sk
        FROM date_dim d
        WHERE d.d_year >= 2023
        AND d.d_week_seq IS NOT NULL
        AND d.d_month_seq IN (SELECT d_month_seq
                              FROM date_dim 
                              WHERE d_year = 2023)
    )
    GROUP BY ws.ws_item_sk
),
SalesWithPromotions AS (
    SELECT 
        r.ws_item_sk,
        r.total_quantity,
        r.total_net_paid,
        p.p_discount_active,
        p.p_promo_name,
        CASE 
            WHEN p.p_discount_active = 'Y' 
            THEN r.total_net_paid * 0.9 
            ELSE r.total_net_paid 
        END AS adjusted_net_paid
    FROM RankedSales r
    LEFT JOIN promotion p ON r.ws_item_sk = p.p_item_sk 
    WHERE r.rank = 1
),
FinalSales AS (
    SELECT 
        swp.ws_item_sk,
        swp.total_quantity,
        swp.total_net_paid,
        swp.adjusted_net_paid,
        COALESCE(pa.ca_city, 'Unknown') AS shipping_city,
        SUM(sws.ss_quantity) OVER (PARTITION BY swp.ws_item_sk ORDER BY swp.total_net_paid DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_quantity
    FROM SalesWithPromotions swp
    LEFT JOIN store_sales sws ON swp.ws_item_sk = sws.ss_item_sk
    LEFT JOIN customer c ON sws.ss_customer_sk = c.c_customer_sk
    LEFT JOIN customer_address pa ON c.c_current_addr_sk = pa.ca_address_sk
)
SELECT 
    f.ws_item_sk,
    f.total_quantity,
    f.total_net_paid,
    f.adjusted_net_paid,
    f.shipping_city,
    f.cumulative_quantity,
    CASE 
        WHEN f.shipping_city IN ('New York', 'Los Angeles') THEN 'Major City'
        ELSE 'Other'
    END AS city_category
FROM FinalSales f
WHERE f.shipping_city IS NOT NULL 
OR f.adjusted_net_paid IS NOT NULL 
ORDER BY f.adjusted_net_paid DESC
LIMIT 100;
