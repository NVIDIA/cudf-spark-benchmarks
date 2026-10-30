
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS rank_by_sales
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2001
        AND dd.d_moy IN (11, 12) 
    GROUP BY 
        ws.ws_item_sk, ws.ws_order_number
),
TopSellingItems AS (
    SELECT 
        ri.i_item_id,
        ri.i_product_name,
        rs.total_quantity_sold,
        rs.total_sales,
        rs.ws_order_number
    FROM 
        RankedSales rs
    JOIN 
        item ri ON rs.ws_item_sk = ri.i_item_sk
    WHERE 
        rs.rank_by_sales <= 10
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    tsi.i_product_name,
    tsi.total_sales
FROM 
    TopSellingItems tsi
JOIN 
    web_sales ws ON tsi.ws_order_number = ws.ws_order_number
JOIN 
    customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
ORDER BY 
    tsi.total_sales DESC;
