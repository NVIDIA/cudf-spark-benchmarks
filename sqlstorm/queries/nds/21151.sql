
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS rank_price,
        SUM(ws_quantity) OVER (PARTITION BY ws_item_sk) AS total_quantity
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 1 AND 365
),
HighValueOrders AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price * ws_quantity) AS total_sales_value
    FROM 
        RankedSales
    WHERE 
        rank_price = 1
    GROUP BY 
        ws_item_sk
),
LowStockItems AS (
    SELECT 
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_stock
    FROM 
        inventory
    GROUP BY 
        inv_item_sk
    HAVING 
        SUM(inv_quantity_on_hand) < 10
),
SalesAndStock AS (
    SELECT 
        hvo.ws_item_sk,
        hvo.total_sales_value,
        lsi.total_stock,
        CASE 
            WHEN lsi.total_stock IS NULL THEN 'Out of Stock'
            WHEN hvo.total_sales_value > 1000 THEN 'High Value'
            ELSE 'Regular Value'
        END AS status
    FROM 
        HighValueOrders hvo
    FULL OUTER JOIN 
        LowStockItems lsi ON hvo.ws_item_sk = lsi.inv_item_sk
)
SELECT 
    s.ws_item_sk,
    COALESCE(s.total_sales_value, 0) AS sales_value,
    COALESCE(s.total_stock, 0) AS stock_level,
    s.status,
    s.total_sales_value * 1.15 AS projected_sales_value,
    CASE 
        WHEN s.status = 'Out of Stock' THEN NULL
        ELSE ROUND(s.total_sales_value / NULLIF(s.total_stock, 0), 2)
    END AS sales_per_stock_unit,
    REPLACE(s.status, ' ', '-') AS formatted_status 
FROM 
    SalesAndStock s
ORDER BY 
    projected_sales_value DESC, 
    sales_value DESC;
