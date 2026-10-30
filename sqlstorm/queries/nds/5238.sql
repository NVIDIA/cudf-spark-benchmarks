
WITH SalesData AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        SUM(ws_ext_discount_amt) AS total_discount,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
ItemDetails AS (
    SELECT 
        i_item_sk,
        i_item_id,
        i_item_desc,
        i_current_price,
        i_brand,
        i_category
    FROM 
        item
),
SalesSummary AS (
    SELECT 
        i.i_item_id AS item_id,
        i.i_item_desc AS item_desc,
        i.i_current_price AS current_price,
        i.i_brand AS brand,
        i.i_category AS category,
        s.total_quantity,
        s.total_sales,
        s.total_discount,
        s.total_profit,
        (s.total_sales - s.total_discount) AS net_sales_after_discount,
        (s.total_profit / NULLIF(s.total_sales, 0)) * 100 AS profit_margin
    FROM 
        SalesData s
    JOIN 
        ItemDetails i ON s.ws_item_sk = i.i_item_sk
)
SELECT 
    item_id,
    item_desc,
    current_price,
    total_quantity,
    total_sales,
    total_discount,
    net_sales_after_discount,
    profit_margin
FROM 
    SalesSummary
ORDER BY 
    profit_margin DESC, total_sales DESC
LIMIT 100;
