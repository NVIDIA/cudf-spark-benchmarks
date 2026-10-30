WITH daily_sales AS (
    SELECT 
        dd.d_date AS sale_date,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_profit) AS avg_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    GROUP BY 
        dd.d_date
),
customer_summary AS (
    SELECT 
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS total_customers,
        SUM(cd.cd_purchase_estimate) AS total_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender
),
warehouse_sales AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ws.ws_ext_sales_price) AS warehouse_sales
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
)
SELECT 
    ds.sale_date,
    ds.total_sales,
    ds.total_orders,
    ds.avg_profit,
    cs.total_customers,
    cs.total_purchase_estimate,
    ws.warehouse_sales
FROM 
    daily_sales ds
JOIN 
    customer_summary cs ON ds.sale_date BETWEEN '2001-01-01' AND '2001-12-31'
JOIN 
    warehouse_sales ws ON ds.sale_date = '2001-01-01'  
ORDER BY 
    ds.sale_date DESC;