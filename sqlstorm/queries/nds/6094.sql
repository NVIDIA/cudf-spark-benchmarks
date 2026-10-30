
WITH SalesSummary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (
            SELECT MAX(d_date_sk) 
            FROM date_dim 
            WHERE d_year = 2023
        ) - 30 AND (
            SELECT MAX(d_date_sk) 
            FROM date_dim 
            WHERE d_year = 2023
        )
    GROUP BY 
        ws_item_sk
), TopItems AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        ss.total_quantity,
        ss.total_net_profit,
        ss.total_orders,
        RANK() OVER (ORDER BY ss.total_net_profit DESC) AS profit_rank,
        RANK() OVER (ORDER BY ss.total_quantity DESC) AS quantity_rank
    FROM 
        SalesSummary ss
    JOIN 
        item i ON ss.ws_item_sk = i.i_item_sk
)
SELECT 
    ti.i_item_id,
    ti.i_item_desc,
    ti.total_quantity,
    ti.total_net_profit,
    ti.total_orders
FROM 
    TopItems ti
WHERE 
    ti.profit_rank <= 10 OR ti.quantity_rank <= 10
ORDER BY 
    ti.total_net_profit DESC, ti.total_quantity DESC;
