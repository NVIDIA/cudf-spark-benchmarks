
WITH sales_summary AS (
    SELECT 
        d.d_year,
        i.i_category,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        d.d_year BETWEEN 2018 AND 2023
    GROUP BY 
        d.d_year, i.i_category
)
SELECT 
    s.d_year,
    s.i_category,
    s.total_quantity_sold,
    s.total_net_profit,
    s.total_orders,
    CASE 
        WHEN s.total_orders > 0 THEN s.total_net_profit / s.total_orders 
        ELSE 0 
    END AS avg_order_profit,
    ROW_NUMBER() OVER (PARTITION BY s.d_year ORDER BY s.total_net_profit DESC) AS rank
FROM 
    sales_summary s
WHERE 
    s.total_net_profit > 10000
ORDER BY 
    s.d_year, rank;
