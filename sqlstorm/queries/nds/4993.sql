
WITH SalesData AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_ext_sales_price) AS total_sales_amount,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS row_num
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk,
        ws_item_sk
),
TopSales AS (
    SELECT 
        s.ws_item_sk,
        s.total_quantity_sold,
        s.total_sales_amount,
        i.i_item_desc,
        i.i_current_price
    FROM 
        SalesData s
    JOIN 
        item i ON s.ws_item_sk = i.i_item_sk
    WHERE 
        s.row_num = 1
),
CustomerReturns AS (
    SELECT 
        cr_item_sk,
        SUM(cr_return_quantity) AS total_returned_quantity,
        SUM(cr_return_amount) AS total_returned_amount
    FROM 
        catalog_returns
    GROUP BY 
        cr_item_sk
),
OverallPerformance AS (
    SELECT 
        t.ws_item_sk,
        t.total_quantity_sold,
        t.total_sales_amount,
        COALESCE(r.total_returned_quantity, 0) AS total_returned_quantity,
        COALESCE(r.total_returned_amount, 0) AS total_returned_amount,
        (t.total_sales_amount - COALESCE(r.total_returned_amount, 0)) AS net_sales_amount
    FROM 
        TopSales t
    LEFT JOIN 
        CustomerReturns r ON t.ws_item_sk = r.cr_item_sk
)
SELECT 
    o.ws_item_sk,
    o.total_quantity_sold,
    o.total_sales_amount,
    o.total_returned_quantity,
    o.total_returned_amount,
    o.net_sales_amount,
    i.i_brand,
    i.i_category
FROM 
    OverallPerformance o
JOIN 
    item i ON o.ws_item_sk = i.i_item_sk
WHERE 
    o.net_sales_amount > 1000 AND
    i.i_brand IS NOT NULL AND
    i.i_category IN (SELECT DISTINCT i_category FROM item WHERE i_current_price > 50)
ORDER BY 
    o.net_sales_amount DESC
LIMIT 10;
