
WITH SalesData AS (
    SELECT 
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_sales_price) AS total_sales_price
    FROM 
        catalog_sales
    GROUP BY 
        cs_item_sk
),
ItemData AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price
    FROM 
        item i
)
SELECT 
    id.i_item_desc,
    sd.total_quantity,
    sd.total_sales_price,
    id.i_current_price,
    (sd.total_sales_price - (sd.total_quantity * id.i_current_price)) AS profit_margin
FROM 
    SalesData sd
JOIN 
    ItemData id ON sd.cs_item_sk = id.i_item_sk
WHERE 
    (sd.total_sales_price - (sd.total_quantity * id.i_current_price)) > 0
ORDER BY 
    profit_margin DESC
LIMIT 100;
