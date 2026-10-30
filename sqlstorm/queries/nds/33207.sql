
WITH  ranked_returns AS (
    SELECT 
        sr_item_sk, 
        sr_returned_date_sk, 
        SUM(sr_return_quantity) AS total_returned_qty,
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY SUM(sr_return_quantity) DESC) as rank
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk, sr_returned_date_sk
),
item_sales AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_sold_qty,
        SUM(ws_net_paid) AS total_net_paid,
        SUM(ws_net_profit) AS total_net_profit
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
item_inventory AS (
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
    COALESCE(r.total_returned_qty, 0) AS total_returned_qty,
    COALESCE(s.total_sold_qty, 0) AS total_sold_qty,
    COALESCE(iw.total_inventory, 0) AS total_inventory,
    s.total_net_paid,
    s.total_net_profit,
    CASE
        WHEN COALESCE(s.total_sold_qty, 0) = 0 THEN NULL
        ELSE (COALESCE(r.total_returned_qty, 0) * 100.0) / COALESCE(s.total_sold_qty, 1)
    END AS return_percentage
FROM 
    item i
LEFT JOIN 
    ranked_returns r ON i.i_item_sk = r.sr_item_sk AND r.rank = 1
LEFT JOIN 
    item_sales s ON i.i_item_sk = s.ws_item_sk
LEFT JOIN 
    item_inventory iw ON i.i_item_sk = iw.inv_item_sk
WHERE 
    (s.total_net_profit > 1000 OR r.total_returned_qty IS NOT NULL)
ORDER BY 
    return_percentage DESC;
