
WITH  sales_data AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        ws_quantity, 
        ws_net_profit, 
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) as rn
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
item_sales AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        SUM(sd.ws_quantity) AS total_quantity,
        SUM(sd.ws_net_profit) AS total_profit
    FROM 
        item i
    JOIN 
        sales_data sd ON i.i_item_sk = sd.ws_item_sk
    WHERE 
        sd.rn <= 5
    GROUP BY 
        i.i_item_id, i.i_item_desc
),
top_items AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        total_quantity,
        total_profit,
        DENSE_RANK() OVER (ORDER BY total_profit DESC) AS rank
    FROM 
        item_sales i
)
SELECT 
    t.i_item_id,
    t.i_item_desc,
    COALESCE(ROUND(t.total_profit, 2), 0) AS total_profit,
    COALESCE(ROUND(t.total_quantity, 2), 0) AS total_quantity,
    m.cd_marital_status,
    m.cd_gender
FROM 
    top_items t
LEFT JOIN 
    customer_demographics m ON t.rank <= 10 AND m.cd_demo_sk IN (SELECT c.c_current_cdemo_sk FROM customer c)
WHERE 
    t.rank <= 10
ORDER BY 
    t.total_profit DESC;
