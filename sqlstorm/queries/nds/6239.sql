
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_profit) AS total_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_rec_start_date <= (SELECT MAX(d.d_date) FROM date_dim d WHERE d.d_current_year = 'Y')
        AND i.i_rec_end_date IS NULL
    GROUP BY 
        ws.ws_item_sk, ws.ws_order_number
),

TopItems AS (
    SELECT 
        r.ws_item_sk,
        r.total_quantity_sold,
        r.total_net_profit
    FROM 
        RankedSales r
    WHERE 
        r.profit_rank <= 10
)

SELECT 
    i.i_item_id,
    i.i_product_name,
    ti.total_quantity_sold,
    ti.total_net_profit,
    CAST(AVG(ti.total_net_profit) AS STRING) AS avg_net_profit
FROM 
    item i
JOIN 
    TopItems ti ON i.i_item_sk = ti.ws_item_sk
GROUP BY 
    i.i_item_id, i.i_product_name, ti.total_quantity_sold, ti.total_net_profit
ORDER BY 
    ti.total_net_profit DESC;
