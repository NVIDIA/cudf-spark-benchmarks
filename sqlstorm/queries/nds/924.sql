WITH sales_data AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (
            SELECT d_date_sk 
            FROM date_dim 
            WHERE d_year = 2000
        )
), 
top_sales AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        SUM(sd.ws_quantity) AS total_quantity,
        SUM(sd.ws_net_profit) AS total_net_profit
    FROM 
        sales_data sd
    JOIN 
        item ON sd.ws_item_sk = item.i_item_sk
    WHERE 
        sd.rn = 1 
    GROUP BY 
        item.i_item_id, item.i_item_desc
),
avg_profit AS (
    SELECT 
        AVG(total_net_profit) AS average_profit
    FROM 
        top_sales
)
SELECT 
    ts.i_item_id,
    ts.i_item_desc,
    ts.total_quantity,
    ts.total_net_profit,
    CASE 
        WHEN ts.total_net_profit > (SELECT average_profit FROM avg_profit) THEN 'Above Average'
        WHEN ts.total_net_profit < (SELECT average_profit FROM avg_profit) THEN 'Below Average'
        ELSE 'Average'
    END AS profit_category
FROM 
    top_sales ts
ORDER BY 
    ts.total_net_profit DESC
LIMIT 10;