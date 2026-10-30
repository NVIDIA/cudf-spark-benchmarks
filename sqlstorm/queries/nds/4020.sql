
WITH SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
                           AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk
),
TopItems AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_profit,
        COALESCE(i.i_item_desc, 'UNKNOWN') AS item_description,
        ROW_NUMBER() OVER (ORDER BY sd.total_profit DESC) AS item_rank
    FROM 
        SalesData sd
    LEFT JOIN 
        item i ON sd.ws_item_sk = i.i_item_sk
)
SELECT 
    ti.item_rank,
    ti.item_description,
    ti.total_quantity,
    ti.total_profit,
    CASE 
        WHEN ti.total_profit IS NULL THEN 'No Profit'
        WHEN ti.total_profit < 0 THEN 'Loss'
        ELSE 'Profit'
    END AS profit_status,
    (SELECT COUNT(DISTINCT ws_bill_customer_sk) 
     FROM web_sales 
     WHERE ws_item_sk = ti.ws_item_sk) AS unique_customers
FROM 
    TopItems ti
WHERE 
    ti.item_rank <= 10
ORDER BY 
    ti.total_profit DESC;
