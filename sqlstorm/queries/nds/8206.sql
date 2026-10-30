
WITH RankedSales AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity, 
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 90 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk
),
TopItems AS (
    SELECT 
        rs.ws_item_sk,
        rs.total_quantity,
        rs.total_sales,
        rs.order_count,
        i.i_item_desc,
        i.i_current_price,
        i.i_brand,
        cs.cs_sales_price AS catalog_sales_price
    FROM 
        RankedSales rs
    JOIN 
        item i ON rs.ws_item_sk = i.i_item_sk
    LEFT JOIN 
        catalog_sales cs ON rs.ws_item_sk = cs.cs_item_sk
    WHERE 
        rs.sales_rank <= 10
)
SELECT 
    ti.ws_item_sk,
    ti.i_item_desc,
    ti.total_quantity,
    ti.total_sales,
    ti.order_count,
    ti.i_current_price,
    ti.i_brand,
    AVG(ti.catalog_sales_price) AS avg_catalog_sales_price
FROM 
    TopItems ti
GROUP BY 
    ti.ws_item_sk, ti.i_item_desc, ti.total_quantity, ti.total_sales, ti.order_count, ti.i_current_price, ti.i_brand
ORDER BY 
    ti.total_sales DESC;
