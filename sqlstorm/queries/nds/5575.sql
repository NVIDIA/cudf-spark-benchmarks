WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_ext_sales_price) AS total_sales_amount,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        dd.d_year = 2001 AND dd.d_moy IN (11, 12) 
    GROUP BY 
        ws.ws_item_sk
),
TopItems AS (
    SELECT 
        ri.i_item_id,
        ri.i_item_desc,
        rs.total_quantity_sold,
        rs.total_sales_amount
    FROM 
        RankedSales rs
    JOIN 
        item ri ON rs.ws_item_sk = ri.i_item_sk
    WHERE 
        rs.sales_rank <= 10
)
SELECT 
    ti.i_item_id,
    ti.i_item_desc,
    ti.total_quantity_sold,
    ti.total_sales_amount,
    ROUND(ti.total_sales_amount / NULLIF(ti.total_quantity_sold, 0), 2) AS avg_sales_price
FROM 
    TopItems ti
ORDER BY 
    ti.total_sales_amount DESC;