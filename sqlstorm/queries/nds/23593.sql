
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS price_rank
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 2000000 AND 2100000
),
customer_stats AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COUNT(DISTINCT cr.cr_order_number) AS total_returns,
        SUM(cr.cr_return_amount) AS total_return_amount
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN catalog_returns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
    GROUP BY c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
),
inventory_status AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity,
        MIN(inv.inv_date_sk) AS first_date,
        MAX(inv.inv_date_sk) AS last_date
    FROM inventory inv
    GROUP BY inv.inv_item_sk
),
final_report AS (
    SELECT 
        cs.c_customer_sk,
        SUM(cs.total_returns) AS total_customer_returns,
        MAX(cs.total_return_amount) AS max_return_amount,
        COALESCE(SUM(rs.ws_quantity * rs.ws_sales_price), 0) AS total_sales_value,
        inv.total_quantity AS quantity_on_hand,
        (CASE 
            WHEN inv.total_quantity IS NULL OR inv.total_quantity = 0 THEN 'OUT OF STOCK' 
            ELSE 'IN STOCK' 
        END) AS inventory_state
    FROM customer_stats cs
    JOIN ranked_sales rs ON cs.c_customer_sk = rs.ws_item_sk
    JOIN inventory_status inv ON rs.ws_item_sk = inv.inv_item_sk
    GROUP BY cs.c_customer_sk, inv.total_quantity
)
SELECT 
    fr.c_customer_sk,
    fr.total_customer_returns,
    fr.max_return_amount,
    fr.total_sales_value,
    fr.inventory_state,
    (SELECT 
        COUNT(*) 
     FROM store_sales ss 
     WHERE ss.ss_sold_date_sk BETWEEN 2000000 AND 2100000 
     AND ss.ss_item_sk = (SELECT MIN(i.i_item_sk) FROM item i WHERE i.i_current_price > 100)
    ) AS store_sales_count
FROM final_report fr 
WHERE (fr.total_sales_value > 1000 OR fr.total_customer_returns > 5) 
AND fr.max_return_amount IS NOT NULL
ORDER BY fr.total_sales_value DESC
LIMIT 100 OFFSET 50;
