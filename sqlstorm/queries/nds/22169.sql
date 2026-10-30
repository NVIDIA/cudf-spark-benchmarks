
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk, 
        ws.ws_order_number, 
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS rank_sales
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk > (SELECT MAX(d_date_sk) - 30 FROM date_dim)
    GROUP BY 
        ws.ws_item_sk, 
        ws.ws_order_number
), 
FilteredSales AS (
    SELECT 
        rs.ws_item_sk, 
        rs.total_quantity, 
        rs.total_sales,
        CASE
            WHEN rs.total_sales IS NULL THEN 'No Sales'
            WHEN rs.total_sales < 100 THEN 'Low Sales'
            WHEN rs.total_sales BETWEEN 100 AND 500 THEN 'Moderate Sales'
            ELSE 'High Sales'
        END AS sales_category
    FROM 
        RankedSales rs
    WHERE 
        rs.rank_sales <= 5
), 
TopItems AS (
    SELECT 
        fs.ws_item_sk, 
        fs.total_quantity, 
        fs.total_sales,
        fs.sales_category,
        COALESCE(i.i_product_name, 'Unnamed Product') AS product_name
    FROM 
        FilteredSales fs
    LEFT JOIN 
        item i ON fs.ws_item_sk = i.i_item_sk
), 
WarehouseData AS (
    SELECT 
        w.w_warehouse_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price) AS warehouse_sales
    FROM 
        warehouse w
    JOIN 
        web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY 
        w.w_warehouse_sk
)

SELECT 
    ti.product_name, 
    ti.total_quantity, 
    ti.total_sales, 
    ti.sales_category,
    wd.total_orders,
    wd.warehouse_sales
FROM 
    TopItems ti
JOIN 
    WarehouseData wd ON ti.ws_item_sk IN (SELECT inv.inv_item_sk FROM inventory inv WHERE inv.inv_quantity_on_hand > 0)
WHERE 
    EXISTS (SELECT 1 FROM catalog_sales cs WHERE cs.cs_item_sk = ti.ws_item_sk AND cs.cs_net_profit > 0)
    OR wd.warehouse_sales > (SELECT AVG(wd2.warehouse_sales) FROM WarehouseData wd2)
ORDER BY 
    ti.total_sales DESC
LIMIT 10 OFFSET 0;
