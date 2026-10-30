
WITH sales_summary AS (
    SELECT 
        w.w_warehouse_name,
        d.d_year,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_profit) AS avg_net_profit,
        SUM(ws.ws_ext_discount_amt) AS total_discount
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2021 AND 2023
    GROUP BY 
        w.w_warehouse_name, d.d_year
),
customer_summary AS (
    SELECT 
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS total_customers,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_marital_status = 'M'
    GROUP BY 
        cd.cd_gender
),
final_summary AS (
    SELECT 
        ss.w_warehouse_name,
        ss.d_year,
        ss.total_sales,
        ss.total_orders,
        ss.avg_net_profit,
        cs.cd_gender,
        cs.total_customers,
        cs.avg_purchase_estimate
    FROM 
        sales_summary ss
    JOIN 
        customer_summary cs ON 1=1
)
SELECT 
    f.w_warehouse_name,
    f.d_year,
    f.total_sales,
    f.total_orders,
    f.avg_net_profit,
    f.cd_gender,
    f.total_customers,
    f.avg_purchase_estimate
FROM 
    final_summary f
ORDER BY 
    f.d_year DESC, f.total_sales DESC;
