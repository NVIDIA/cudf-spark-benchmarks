WITH SalesData AS (
    SELECT 
        ws_item_sk,
        ws_sales_price,
        ws_quantity,
        (ws_sales_price * ws_quantity) AS total_sales,
        RANK() OVER(PARTITION BY ws_item_sk ORDER BY (ws_sales_price * ws_quantity) DESC) as sales_rank
    FROM web_sales
    WHERE ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_date = cast('2002-10-01' as date))
),
ItemDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_brand,
        i.i_category,
        COALESCE(CAST(SUM(ws_quantity) AS DECIMAL(10, 2)), 0) AS total_quantity,
        COALESCE(CAST(SUM(ws_sales_price) AS DECIMAL(10, 2)), 0) AS total_price
    FROM item i
    LEFT JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY i.i_item_sk, i.i_item_desc, i.i_brand, i.i_category
)
SELECT 
    id.i_item_sk,
    id.i_item_desc,
    id.i_brand,
    id.i_category,
    id.total_quantity,
    id.total_price,
    sd.total_sales,
    sd.sales_rank
FROM ItemDetails id
LEFT JOIN SalesData sd ON id.i_item_sk = sd.ws_item_sk
WHERE id.total_quantity > 0
ORDER BY id.total_price DESC, sd.sales_rank
LIMIT 10;