
WITH RankedSales AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_ext_sales_price DESC) AS rank 
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
),
TopSellingItems AS (
    SELECT 
        r.ws_item_sk,
        SUM(r.ws_quantity) AS total_quantity,
        SUM(r.ws_ext_sales_price) AS total_sales
    FROM 
        RankedSales r 
    WHERE 
        r.rank <= 10
    GROUP BY 
        r.ws_item_sk 
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    tsi.total_quantity,
    tsi.total_sales,
    (CASE WHEN tsi.total_sales > 10000 THEN 'High' ELSE 'Low' END) AS sales_category
FROM 
    TopSellingItems tsi
JOIN 
    item i ON tsi.ws_item_sk = i.i_item_sk
ORDER BY 
    tsi.total_sales DESC
LIMIT 50;
