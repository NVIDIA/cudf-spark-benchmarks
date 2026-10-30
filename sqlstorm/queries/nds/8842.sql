WITH SalesSummary AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_quantity) AS total_quantity_sold
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2001 AND 
        d.d_moy IN (11, 12) 
    GROUP BY 
        ws.ws_item_sk
),
TopProducts AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        ss.total_net_profit,
        ss.total_orders,
        ss.total_quantity_sold,
        RANK() OVER (ORDER BY ss.total_net_profit DESC) AS rank
    FROM 
        SalesSummary ss
    JOIN 
        item i ON ss.ws_item_sk = i.i_item_sk
)
SELECT 
    tp.i_item_id,
    tp.i_item_desc,
    tp.total_net_profit,
    tp.total_orders,
    tp.total_quantity_sold
FROM 
    TopProducts tp
WHERE 
    tp.rank <= 10
ORDER BY 
    tp.total_net_profit DESC;