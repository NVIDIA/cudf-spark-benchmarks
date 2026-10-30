
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_quantity) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.ws_item_sk
),
TopItems AS (
    SELECT 
        ri.ws_item_sk,
        ri.total_quantity_sold,
        ri.total_sales,
        i.i_product_name,
        i.i_category
    FROM 
        RankedSales ri
    JOIN 
        item i ON ri.ws_item_sk = i.i_item_sk
    WHERE 
        ri.sales_rank <= 10
)
SELECT 
    ti.i_product_name,
    ti.i_category,
    ti.total_quantity_sold,
    ti.total_sales,
    ROUND(ti.total_sales / NULLIF(ti.total_quantity_sold, 0), 2) AS average_sales_price
FROM 
    TopItems ti
ORDER BY 
    ti.total_sales DESC;
