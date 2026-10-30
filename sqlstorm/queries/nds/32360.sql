
WITH  monthly_sales AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        date_dim d
    JOIN web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        d.d_year, d.d_month_seq
),
top_sales AS (
    SELECT 
        d_year,
        d_month_seq,
        total_sales,
        sales_rank
    FROM 
        monthly_sales
    WHERE 
        sales_rank <= 12
),
customer_stats AS (
    SELECT 
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS num_customers,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender
),
warehouse_stats AS (
    SELECT 
        w.w_warehouse_id,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        warehouse w
    JOIN web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
)
SELECT 
    ts.d_year,
    ts.d_month_seq,
    cs.cd_gender,
    cs.num_customers,
    cs.avg_purchase_estimate,
    ws.w_warehouse_id,
    ws.total_orders,
    ws.total_profit
FROM 
    top_sales ts
LEFT JOIN customer_stats cs ON cs.avg_purchase_estimate IS NOT NULL
INNER JOIN warehouse_stats ws ON ws.total_orders IS NOT NULL
ORDER BY 
    ts.d_year, ts.d_month_seq, cs.cd_gender;
