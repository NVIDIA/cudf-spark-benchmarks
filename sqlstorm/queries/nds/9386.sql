
WITH sales_data AS (
    SELECT 
        ws.ws_sold_date_sk,
        w.w_warehouse_name,
        i.i_item_id,
        SUM(ws.ws_quantity) AS total_sales,
        SUM(ws.ws_sales_price) AS total_revenue,
        AVG(ws.ws_net_profit) AS avg_profit
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 20220101 AND 20221231
    GROUP BY 
        ws.ws_sold_date_sk, w.w_warehouse_name, i.i_item_id
),
monthly_sales AS (
    SELECT 
        DATE_TRUNC('month', d.d_date) AS sale_month,
        SUM(sd.total_sales) AS total_sales_per_month,
        SUM(sd.total_revenue) AS total_revenue_per_month,
        AVG(sd.avg_profit) AS avg_profit_per_month
    FROM
        sales_data sd
    JOIN 
        date_dim d ON sd.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        sale_month
)
SELECT 
    sale_month,
    total_sales_per_month,
    total_revenue_per_month,
    avg_profit_per_month,
    RANK() OVER (ORDER BY total_revenue_per_month DESC) AS revenue_rank
FROM 
    monthly_sales
ORDER BY 
    sale_month;
