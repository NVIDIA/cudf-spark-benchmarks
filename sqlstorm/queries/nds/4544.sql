
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS rn,
        SUM(ws_quantity) OVER (PARTITION BY ws_item_sk) AS total_quantity
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
),
FilteredSales AS (
    SELECT 
        rs.ws_item_sk,
        rs.ws_order_number,
        rs.ws_sales_price,
        rs.total_quantity
    FROM 
        RankedSales rs
    WHERE 
        rs.rn = 1
),
SalesSummary AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        fs.total_quantity,
        fs.ws_sales_price,
        (fs.ws_sales_price * fs.total_quantity) AS total_revenue
    FROM 
        FilteredSales fs
    JOIN 
        item i ON fs.ws_item_sk = i.i_item_sk
)
SELECT 
    ss.i_item_id,
    ss.i_item_desc,
    ss.total_quantity,
    ss.total_revenue,
    COALESCE(sm.sm_type, 'Not Shipped') AS ship_mode
FROM 
    SalesSummary ss
LEFT JOIN 
    ship_mode sm ON ss.ws_sales_price > 100 AND sm.sm_ship_mode_sk = (SELECT MAX(sm_ship_mode_sk) FROM ship_mode)
WHERE 
    ss.total_revenue > 1000
ORDER BY 
    ss.total_revenue DESC
LIMIT 10;
