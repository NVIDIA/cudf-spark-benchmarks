WITH SalesData AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity, 
        SUM(ws_ext_sales_price) AS total_sales, 
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 
        (SELECT d_date_sk FROM date_dim WHERE d_date = '2001-01-01') AND 
        (SELECT d_date_sk FROM date_dim WHERE d_date = '2001-12-31')
    GROUP BY ws_sold_date_sk, ws_item_sk
),
TopSellingItems AS (
    SELECT 
        ws_item_sk, 
        total_quantity, 
        total_sales,
        RANK() OVER (ORDER BY total_sales DESC) AS ranking
    FROM SalesData
)
SELECT 
    i.i_item_id, 
    i.i_item_desc, 
    tsi.total_quantity, 
    tsi.total_sales
FROM TopSellingItems tsi
JOIN item i ON tsi.ws_item_sk = i.i_item_sk
WHERE tsi.ranking <= 10
ORDER BY tsi.total_sales DESC;