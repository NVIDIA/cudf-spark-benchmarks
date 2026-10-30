
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2001
        AND dd.d_moy IN (6, 7)  
    GROUP BY 
        ws.ws_item_sk
),

TopItems AS (
    SELECT 
        ri.ws_item_sk,
        ri.total_quantity,
        ri.total_sales,
        i.i_item_desc,
        i.i_brand,
        i.i_category
    FROM 
        RankedSales ri
    JOIN 
        item i ON ri.ws_item_sk = i.i_item_sk
    WHERE 
        ri.rank <= 10
),

SalesByCategory AS (
    SELECT 
        ti.i_category,
        SUM(ti.total_sales) AS category_sales
    FROM 
        TopItems ti
    GROUP BY 
        ti.i_category
)

SELECT 
    tbc.category,
    tbc.total_sales,
    COALESCE(ROUND((tbc.total_sales / (SELECT SUM(category_sales) FROM SalesByCategory)) * 100, 2), 0) AS percentage_of_total
FROM 
    (SELECT i_category AS category, SUM(category_sales) AS total_sales FROM SalesByCategory GROUP BY i_category) tbc
ORDER BY 
    tbc.total_sales DESC;
