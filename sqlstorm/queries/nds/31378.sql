
WITH  sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk
), customer_returns AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_quantity) AS total_return_quantity,
        SUM(wr_return_amt) AS total_return_amount
    FROM 
        web_returns
    GROUP BY 
        wr_item_sk
), inventory_data AS (
    SELECT 
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory
    GROUP BY 
        inv_item_sk
)
SELECT 
    COALESCE(ss.ws_item_sk, ir.inv_item_sk) AS item_sk,
    COALESCE(ss.total_quantity, 0) AS sold_quantity,
    COALESCE(ss.total_sales, 0) AS sold_amount,
    COALESCE(cr.total_return_quantity, 0) AS returned_quantity,
    COALESCE(cr.total_return_amount, 0) AS returned_amount,
    COALESCE(ir.total_inventory, 0) AS inventory_quantity,
    CASE 
        WHEN COALESCE(ir.total_inventory, 0) < 50 THEN 'Low Stock'
        WHEN COALESCE(ir.total_inventory, 0) BETWEEN 50 AND 150 THEN 'Moderate Stock'
        ELSE 'High Stock'
    END AS stock_status
FROM 
    sales_summary ss
FULL OUTER JOIN customer_returns cr ON ss.ws_item_sk = cr.wr_item_sk
FULL OUTER JOIN inventory_data ir ON ss.ws_item_sk = ir.inv_item_sk OR cr.wr_item_sk = ir.inv_item_sk
WHERE 
    (COALESCE(ss.total_sales, 0) + COALESCE(cr.total_return_amount, 0)) > 1000
    AND ir.total_inventory IS NOT NULL
ORDER BY 
    stock_status, sold_amount DESC;
