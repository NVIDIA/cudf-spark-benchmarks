
WITH sales_data AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY ws_sold_date_sk, ws_item_sk
),
top_items AS (
    SELECT 
        sd.ws_item_sk,
        i.i_product_name,
        i.i_brand,
        RANK() OVER (ORDER BY sd.total_net_profit DESC) AS item_rank
    FROM sales_data sd
    JOIN item i ON sd.ws_item_sk = i.i_item_sk
)
SELECT 
    ti.item_rank,
    ti.i_product_name,
    ti.i_brand,
    sd.total_quantity,
    sd.total_net_profit
FROM top_items ti
JOIN sales_data sd ON ti.ws_item_sk = sd.ws_item_sk
WHERE ti.item_rank <= 10
ORDER BY ti.item_rank;
