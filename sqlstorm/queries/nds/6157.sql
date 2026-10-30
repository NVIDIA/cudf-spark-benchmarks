
WITH sales_summary AS (
    SELECT 
        w.w_warehouse_name,
        COALESCE(SUM(ws.ws_quantity), 0) AS total_quantity_sold,
        COALESCE(SUM(ws.ws_net_paid), 0) AS total_sales_amount,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid_inc_tax) AS avg_order_value
    FROM 
        warehouse w
    LEFT JOIN 
        web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d.d_date_sk FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY 
        w.w_warehouse_name
),
customer_demographics_summary AS (
    SELECT 
        cd.cd_gender, 
        COUNT(DISTINCT c.c_customer_sk) AS total_customers,
        SUM(CASE WHEN cd.cd_marital_status = 'M' THEN 1 ELSE 0 END) AS married_count,
        SUM(CASE WHEN cd.cd_marital_status = 'S' THEN 1 ELSE 0 END) AS single_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender
)
SELECT 
    s.w_warehouse_name,
    s.total_quantity_sold,
    s.total_sales_amount,
    s.total_orders,
    s.avg_order_value,
    d.cd_gender,
    d.total_customers,
    d.married_count,
    d.single_count,
    d.avg_purchase_estimate
FROM 
    sales_summary s
CROSS JOIN 
    customer_demographics_summary d
ORDER BY 
    s.total_sales_amount DESC, d.total_customers DESC
LIMIT 10;
