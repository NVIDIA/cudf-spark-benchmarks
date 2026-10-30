
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM web_sales
    WHERE ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY ws_item_sk
),
AddressCounts AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT ca_address_sk) AS address_count
    FROM customer_address
    GROUP BY ca_state
),
CustomerStats AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
ItemPromotion AS (
    SELECT 
        p.p_item_sk,
        CASE
            WHEN p.p_discount_active = 'Y' THEN 'Active'
            ELSE 'Inactive'
        END AS promotion_status,
        COUNT(p.p_promo_sk) AS promo_count
    FROM promotion p
    WHERE p.p_start_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    AND p.p_end_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY p.p_item_sk, p.p_discount_active
)
SELECT
    i.i_item_id,
    ir.total_quantity,
    ir.total_net_profit,
    COALESCE(ac.address_count, 0) AS unique_address_count,
    cs.gender_rank,
    ip.promotion_status,
    ip.promo_count
FROM item i
JOIN RankedSales ir ON i.i_item_sk = ir.ws_item_sk AND ir.rank = 1
LEFT JOIN AddressCounts ac ON ac.ca_state = (SELECT ca_state FROM customer_address WHERE ca_address_sk = (SELECT c.c_current_addr_sk FROM customer c WHERE c.c_customer_sk = (SELECT MIN(c_customer_sk) FROM customer)))
LEFT JOIN CustomerStats cs ON cs.c_customer_id = (SELECT c.c_customer_id FROM customer c ORDER BY c.c_customer_sk LIMIT 1) 
LEFT JOIN ItemPromotion ip ON ip.p_item_sk = i.i_item_sk
WHERE 
    (ir.total_net_profit > 0 OR EXISTS (SELECT 1 FROM web_returns wr WHERE wr.wr_item_sk = i.i_item_sk AND wr.wr_return_quantity > 0))
    AND i.i_item_sk NOT IN (SELECT sr_item_sk FROM store_returns)
ORDER BY ir.total_net_profit DESC, unique_address_count DESC
LIMIT 50;
