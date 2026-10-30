
WITH  sales_data AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) as rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) - 30 FROM date_dim d)
), return_data AS (
    SELECT
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt) AS total_return_amt
    FROM 
        store_returns
    GROUP BY sr_item_sk
), inventory_data AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_stock
    FROM 
        inventory inv
    GROUP BY inv.inv_item_sk
), item_metrics AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        COALESCE(sd.ws_quantity, 0) AS total_sold_qty,
        COALESCE(sd.ws_sales_price, 0) AS avg_sales_price,
        COALESCE(r.total_returns, 0) AS returns_qty,
        COALESCE(r.total_return_amt, 0) AS returns_amt,
        COALESCE(id.total_stock, 0) AS current_stock
    FROM 
        item i
    LEFT JOIN sales_data sd ON i.i_item_sk = sd.ws_item_sk
    LEFT JOIN return_data r ON i.i_item_sk = r.sr_item_sk
    LEFT JOIN inventory_data id ON i.i_item_sk = id.inv_item_sk
)
SELECT 
    im.i_item_sk,
    im.i_item_desc,
    im.total_sold_qty,
    im.avg_sales_price,
    im.returns_qty,
    im.returns_amt,
    im.current_stock,
    CASE 
        WHEN im.total_sold_qty > 100 THEN 'High Sales'
        WHEN im.total_sold_qty BETWEEN 50 AND 100 THEN 'Moderate Sales'
        ELSE 'Low Sales'
    END AS sales_category
FROM 
    item_metrics im
WHERE 
    im.current_stock IS NOT NULL 
    AND (im.returns_qty IS NULL OR im.returns_qty < 5)
ORDER BY 
    im.total_sold_qty DESC, im.i_item_desc
LIMIT 10;
