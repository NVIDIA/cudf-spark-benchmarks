
WITH SalesSummary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 10000 AND 10050
    GROUP BY 
        ws_item_sk
),
TopSales AS (
    SELECT 
        ws_item_sk AS ss_item_sk, 
        total_quantity, 
        total_sales
    FROM 
        SalesSummary
    WHERE 
        sales_rank <= 10
),
ItemDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        COALESCE(i.i_color, 'Unknown') AS item_color,
        COALESCE(i.i_brand, 'No Brand') AS item_brand,
        i.i_current_price
    FROM 
        item i
)
SELECT 
    id.i_item_sk,
    id.i_item_id,
    id.i_product_name,
    id.item_color,
    id.item_brand,
    COALESCE(ts.total_quantity, 0) AS sold_quantity,
    COALESCE(ts.total_sales, 0.00) AS sales_amount
FROM 
    ItemDetails id
LEFT JOIN 
    TopSales ts ON id.i_item_sk = ts.ss_item_sk
WHERE 
    id.i_current_price > (SELECT AVG(i.i_current_price) FROM item i)
ORDER BY 
    sales_amount DESC
LIMIT 10;
