
WITH return_summary AS (
    SELECT
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returned,
        SUM(wr_return_amt_inc_tax) AS total_return_amount,
        SUM(wr_net_loss) AS total_net_loss
    FROM
        web_returns
    GROUP BY
        wr_item_sk
),
sales_summary AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_net_profit) AS total_net_profit
    FROM
        web_sales
    GROUP BY
        ws_item_sk
),
inventory_summary AS (
    SELECT
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_inventory
    FROM
        inventory
    GROUP BY
        inv_item_sk
)
SELECT
    i.i_item_id,
    COALESCE(s.total_quantity_sold, 0) AS total_quantity_sold,
    COALESCE(s.total_net_profit, 0) AS total_net_profit,
    COALESCE(r.total_returned, 0) AS total_returned,
    COALESCE(r.total_return_amount, 0) AS total_return_amount,
    COALESCE(r.total_net_loss, 0) AS total_net_loss,
    COALESCE(inv.total_inventory, 0) AS total_inventory,
    CASE 
        WHEN COALESCE(s.total_quantity_sold, 0) > 0 THEN 
            (COALESCE(r.total_returned, 0) * 1.0 / COALESCE(s.total_quantity_sold, 1)) * 100
        ELSE 
            NULL 
    END AS return_percentage,
    i.i_brand,
    i.i_category
FROM
    item i
LEFT JOIN
    sales_summary s ON i.i_item_sk = s.ws_item_sk
LEFT JOIN
    return_summary r ON i.i_item_sk = r.wr_item_sk
LEFT JOIN
    inventory_summary inv ON i.i_item_sk = inv.inv_item_sk
WHERE
    COALESCE(s.total_net_profit, 0) > 1000 
    AND (i.i_brand LIKE '%Premium%' OR i.i_category IN (SELECT DISTINCT r.r_reason_desc FROM reason r WHERE r.r_reason_desc IS NOT NULL))
ORDER BY
    total_net_profit DESC
LIMIT 50;
