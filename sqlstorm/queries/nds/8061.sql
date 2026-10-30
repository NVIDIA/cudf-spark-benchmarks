
WITH SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') 
        AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-31')
    GROUP BY 
        ws_item_sk
),
TopItems AS (
    SELECT 
        i_item_id, 
        i_item_desc,
        sd.total_quantity,
        sd.total_profit,
        sd.total_orders,
        RANK() OVER (ORDER BY sd.total_profit DESC) AS profit_rank
    FROM 
        SalesData sd
    JOIN 
        item i ON sd.ws_item_sk = i.i_item_sk
)

SELECT 
    ti.i_item_id,
    ti.i_item_desc,
    ti.total_quantity,
    ti.total_profit,
    ti.total_orders,
    CASE 
        WHEN ti.profit_rank <= 5 THEN 'Top Performer'
        ELSE 'Regular Performer'
    END AS performance_category
FROM 
    TopItems ti
WHERE 
    ti.total_orders > 10
ORDER BY 
    ti.total_profit DESC;
