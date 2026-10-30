
WITH  SalesData AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
TopSales AS (
    SELECT 
        ws_item_sk,
        total_quantity,
        total_sales
    FROM 
        SalesData
    WHERE 
        sales_rank <= 10
),
ItemDetails AS (
    SELECT 
        i_item_sk,
        i_item_desc,
        i_current_price,
        i_brand
    FROM 
        item
)
SELECT 
    i.i_item_sk,
    i.i_item_desc,
    i.i_current_price,
    COALESCE(s.total_quantity, 0) AS total_quantity,
    COALESCE(s.total_sales, 0) AS total_sales,
    CASE 
        WHEN COALESCE(s.total_sales, 0) > 0 THEN ROUND((COALESCE(s.total_sales, 0) / i.i_current_price) * 100, 2) 
        ELSE 0 
    END AS sales_percentage
FROM 
    ItemDetails i
LEFT JOIN 
    TopSales s ON i.i_item_sk = s.ws_item_sk
WHERE 
    i.i_brand IS NOT NULL
ORDER BY 
    sales_percentage DESC
LIMIT 20;
