
WITH sales_data AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        AVG(ws_sales_price) AS avg_sales_price,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 
            (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022) - 30 AND 
            (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        ws_item_sk
),
item_data AS (
    SELECT 
        i_item_sk,
        i_item_desc,
        i_current_price,
        i_category
    FROM 
        item
    WHERE 
        i_current_price > 10.00
        AND i_item_sk IN (SELECT ws_item_sk FROM sales_data)
),
high_profit_items AS (
    SELECT 
        id.i_item_sk,
        id.i_item_desc,
        id.i_current_price,
        sd.total_quantity,
        sd.total_profit,
        sd.order_count,
        RANK() OVER (ORDER BY sd.total_profit DESC) AS profit_rank
    FROM 
        item_data id
    JOIN 
        sales_data sd ON id.i_item_sk = sd.ws_item_sk
    WHERE 
        sd.total_profit > 1000
)
SELECT 
    h.i_item_desc AS item_desc,
    h.i_current_price AS current_price,
    h.total_quantity,
    h.total_profit,
    h.order_count,
    CASE 
        WHEN h.profit_rank <= 10 THEN 'Top 10'
        ELSE 'Others'
    END AS profit_category
FROM 
    high_profit_items h
ORDER BY 
    h.total_profit DESC;
