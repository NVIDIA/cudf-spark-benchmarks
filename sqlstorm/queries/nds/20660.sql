
WITH ranked_sales AS (
    SELECT
        ws_item_sk,
        SUM(ws_net_profit) AS total_net_profit,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank_profit,
        COUNT(DISTINCT ws_order_number) AS order_count,
        COUNT(DISTINCT ws_ship_customer_sk) AS unique_customers
    FROM
        web_sales
    WHERE
        ws_net_profit IS NOT NULL
    GROUP BY
        ws_item_sk
),
inventory_data AS (
    SELECT
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_inventory,
        MAX(inv_warehouse_sk) AS warehouse_id
    FROM
        inventory
    WHERE
        inv_quantity_on_hand > 0
    GROUP BY
        inv_item_sk
),
return_data AS (
    SELECT
        cr_item_sk,
        SUM(cr_return_amount) AS total_return_amount,
        COUNT(DISTINCT cr_order_number) AS returns_count
    FROM
        catalog_returns
    WHERE
        cr_return_amount IS NOT NULL
    GROUP BY
        cr_item_sk
),
final_summary AS (
    SELECT
        inv_data.inv_item_sk,
        COALESCE(ranked_profit.total_net_profit, 0) AS net_profit,
        inv_data.total_inventory,
        COALESCE(return_data.total_return_amount, 0) AS return_amount,
        ranked_profit.rank_profit,
        ranked_profit.order_count,
        ranked_profit.unique_customers
    FROM
        inventory_data inv_data
    LEFT JOIN
        ranked_sales ranked_profit ON inv_data.inv_item_sk = ranked_profit.ws_item_sk
    LEFT JOIN
        return_data ON inv_data.inv_item_sk = return_data.cr_item_sk
)

SELECT
    f.inv_item_sk,
    f.net_profit,
    f.total_inventory,
    f.return_amount,
    f.rank_profit,
    f.order_count,
    f.unique_customers,
    CASE 
        WHEN f.total_inventory = 0 THEN 'Out of Stock'
        WHEN f.net_profit < 0 THEN 'Loss'
        ELSE 'Available'
    END AS stock_status,
    CAST(f.net_profit AS STRING) || ' - Profit/' || CAST(f.return_amount AS STRING) || ' - Returns' AS profit_vs_returns
FROM
    final_summary f
WHERE
    f.rank_profit IS NOT NULL
    AND (f.net_profit > 100 OR (f.return_amount > 0 AND f.total_inventory < 50))
ORDER BY
    f.rank_profit ASC,
    f.unique_customers DESC
LIMIT 20;
