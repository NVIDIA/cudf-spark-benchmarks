
WITH RankedSales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
MaxSales AS (
    SELECT 
        ws_item_sk,
        MAX(total_sales) AS max_sales
    FROM 
        RankedSales
    WHERE 
        rank <= 10
    GROUP BY 
        ws_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    COUNT(ws.ws_order_number) AS total_orders,
    ms.max_sales
FROM 
    item i
JOIN 
    web_sales ws ON i.i_item_sk = ws.ws_item_sk
JOIN 
    MaxSales ms ON ws.ws_item_sk = ms.ws_item_sk
WHERE 
    ws.ws_sold_date_sk IN (
        SELECT 
            d_date_sk
        FROM 
            date_dim
        WHERE 
            d_year = 2023 AND d_moy = 10
    )
GROUP BY 
    i.i_item_id, i.i_item_desc, ms.max_sales
ORDER BY 
    ms.max_sales DESC, total_orders DESC
LIMIT 50;
