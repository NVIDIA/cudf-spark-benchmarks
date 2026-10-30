
WITH sales_summary AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        d.d_week_seq,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2023
    GROUP BY 
        d.d_year, d.d_month_seq, d.d_week_seq
),
customer_summary AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        SUM(ss.total_sales) AS total_sales_by_customer,
        COUNT(DISTINCT ss.total_orders) AS order_count
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    JOIN 
        sales_summary ss ON c.c_customer_sk = ss.total_quantity
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender
),
warehouse_summary AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        warehouse w
    JOIN 
        web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
)
SELECT 
    cs.cd_gender,
    SUM(cs.total_sales_by_customer) AS aggregated_sales,
    AVG(cs.order_count) AS avg_orders_per_customer,
    ws.total_profit,
    ws.order_count AS warehouse_order_count
FROM 
    customer_summary cs
JOIN 
    warehouse_summary ws ON cs.order_count = ws.order_count
GROUP BY 
    cs.cd_gender, ws.total_profit, ws.order_count
ORDER BY 
    aggregated_sales DESC, avg_orders_per_customer DESC;
