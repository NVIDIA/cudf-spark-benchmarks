
WITH SalesData AS (
    SELECT ws_item_sk, 
           SUM(ws_quantity) AS total_quantity_sold, 
           SUM(ws_sales_price) AS total_sales, 
           ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS rank
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 1000000 AND 1000050
    GROUP BY ws_item_sk
),
CustomerReturns AS (
    SELECT cr_item_sk,
           SUM(cr_return_quantity) AS total_returned_quantity
    FROM catalog_returns
    WHERE cr_returned_date_sk BETWEEN 1000000 AND 1000050
    GROUP BY cr_item_sk
),
ItemMetrics AS (
    SELECT i_item_sk,
           COALESCE(sd.total_quantity_sold, 0) AS total_quantity_sold,
           COALESCE(sd.total_sales, 0) AS total_sales,
           COALESCE(cr.total_returned_quantity, 0) AS total_returned_quantity,
           (COALESCE(sd.total_sales, 0) - COALESCE(cr.total_returned_quantity, 0) * i_current_price) AS net_sales
    FROM item i
    LEFT JOIN SalesData sd ON i.i_item_sk = sd.ws_item_sk
    LEFT JOIN CustomerReturns cr ON i.i_item_sk = cr.cr_item_sk
)
SELECT im.i_item_sk,
       im.total_quantity_sold,
       im.total_sales,
       im.total_returned_quantity,
       im.net_sales,
       i.i_product_name,
       ROW_NUMBER() OVER (ORDER BY im.net_sales DESC) AS rank
FROM ItemMetrics im
JOIN item i ON im.i_item_sk = i.i_item_sk
WHERE im.net_sales > 0
AND EXISTS (
    SELECT 1
    FROM customer c
    WHERE c.c_customer_sk IN (
        SELECT ws_bill_customer_sk 
        FROM web_sales 
        WHERE ws_sold_date_sk BETWEEN 1000000 AND 1000050
    ) AND c.c_birth_year < 1980
)
ORDER BY im.net_sales DESC
LIMIT 10;
