
WITH sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        MAX(ws_sold_date_sk) AS last_sale_date
    FROM web_sales
    GROUP BY ws_item_sk
), 
return_summary AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returns,
        SUM(wr_return_amt) AS total_return_amt
    FROM web_returns
    GROUP BY wr_item_sk
),
inventory_summary AS (
    SELECT 
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_inventory
    FROM inventory
    GROUP BY inv_item_sk
)
SELECT 
    i.i_item_id,
    COALESCE(ss.total_quantity, 0) AS total_quantity_sold,
    COALESCE(ss.total_sales, 0) AS total_sales_amount,
    COALESCE(rs.total_returns, 0) AS total_returns,
    COALESCE(rs.total_return_amt, 0) AS total_return_amount,
    COALESCE(inv.total_inventory, 0) AS total_inventory,
    CASE 
        WHEN COALESCE(ss.total_quantity, 0) - COALESCE(rs.total_returns, 0) < 0 THEN 'Negative Inventory'
        ELSE 'Normal Inventory'
    END AS inventory_status,
    CASE 
        WHEN i.i_current_price > 100 THEN 'High Price Item'
        WHEN i.i_current_price BETWEEN 50 AND 100 THEN 'Medium Price Item'
        ELSE 'Low Price Item'
    END AS price_category
FROM item i
LEFT JOIN sales_summary ss ON i.i_item_sk = ss.ws_item_sk
LEFT JOIN return_summary rs ON i.i_item_sk = rs.wr_item_sk
LEFT JOIN inventory_summary inv ON i.i_item_sk = inv.inv_item_sk
WHERE i.i_current_price IS NOT NULL
AND (i.i_brand_id IS NULL OR EXISTS (
    SELECT 1
    FROM customer_demographics cd
    WHERE cd.cd_demo_sk = i.i_brand_id
    AND cd.cd_marital_status = 'M'
))
ORDER BY total_sales_amount DESC
LIMIT 100;
