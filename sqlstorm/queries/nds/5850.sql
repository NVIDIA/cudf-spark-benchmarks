
WITH SalesAggregate AS (
    SELECT 
        w.w_warehouse_id AS warehouse_id,
        d.d_year,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        AVG(ws.ws_sales_price) AS average_sales_price
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        w.w_warehouse_id, d.d_year
),
TopSales AS (
    SELECT 
        warehouse_id,
        d_year,
        RANK() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank,
        total_quantity_sold,
        total_sales,
        average_sales_price
    FROM 
        SalesAggregate
)
SELECT 
    t.warehouse_id,
    t.d_year,
    t.total_quantity_sold,
    t.total_sales,
    t.average_sales_price
FROM 
    TopSales t
WHERE 
    t.sales_rank <= 3
ORDER BY 
    t.d_year, t.sales_rank;
