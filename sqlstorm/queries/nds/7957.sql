
WITH sales_summary AS (
    SELECT 
        d.d_year AS year,
        d.d_month_seq AS month,
        item.i_category AS category,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    JOIN 
        item ON ws.ws_item_sk = item.i_item_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2019 AND 2023
    GROUP BY 
        d.d_year, d.d_month_seq, item.i_category
),
average_sales AS (
    SELECT 
        year,
        month,
        category,
        AVG(total_quantity) AS avg_quantity,
        AVG(total_net_profit) AS avg_net_profit,
        AVG(order_count) AS avg_order_count
    FROM 
        sales_summary
    GROUP BY 
        year, month, category
)
SELECT 
    a.year,
    a.month,
    a.category,
    a.avg_quantity,
    a.avg_net_profit,
    a.avg_order_count,
    RANK() OVER (PARTITION BY a.year, a.month ORDER BY a.avg_net_profit DESC) AS profit_rank,
    DENSE_RANK() OVER (PARTITION BY a.year ORDER BY a.avg_quantity DESC) AS quantity_rank
FROM 
    average_sales a
ORDER BY 
    a.year, a.month, a.avg_net_profit DESC, a.avg_quantity DESC;
