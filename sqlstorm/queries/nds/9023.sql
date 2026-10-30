
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk, 
        i.i_item_desc, 
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023 AND d.d_month_seq IN (1, 2, 3) 
    GROUP BY 
        ws.ws_item_sk, i.i_item_desc, i.i_category
), 
TopSellingItems AS (
    SELECT 
        ws_item_sk, 
        i_item_desc, 
        total_quantity_sold, 
        total_sales
    FROM 
        RankedSales
    WHERE 
        sales_rank <= 10
)
SELECT 
    t.ws_item_sk, 
    t.i_item_desc, 
    t.total_quantity_sold, 
    t.total_sales, 
    wd.w_warehouse_name, 
    w.sm_ship_mode_sk, 
    w.sm_carrier
FROM 
    TopSellingItems t
JOIN 
    inventory inv ON t.ws_item_sk = inv.inv_item_sk
JOIN 
    warehouse wd ON inv.inv_warehouse_sk = wd.w_warehouse_sk
JOIN 
    ship_mode w ON w.sm_ship_mode_sk = inv.inv_warehouse_sk 
ORDER BY 
    t.total_sales DESC;
