
WITH SalesData AS (
    SELECT 
        ss_item_sk,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_ext_sales_price) AS total_sales
    FROM 
        store_sales
    GROUP BY 
        ss_item_sk
),
ItemDetails AS (
    SELECT 
        i_item_sk,
        i_product_name,
        i_current_price
    FROM 
        item
)
SELECT 
    id.i_product_name,
    id.i_current_price,
    sd.total_quantity,
    sd.total_sales
FROM 
    SalesData sd
JOIN 
    ItemDetails id ON sd.ss_item_sk = id.i_item_sk
ORDER BY 
    sd.total_sales DESC
LIMIT 100;
