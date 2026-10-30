
WITH sales_summary AS (
    SELECT 
        w.w_warehouse_id,
        d.d_year,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS total_customers
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        w.w_warehouse_id, d.d_year
),
demographics_summary AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT c.c_customer_sk) AS total_customers,
        SUM(ws.ws_net_paid) AS total_sales
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
)
SELECT 
    ss.w_warehouse_id,
    ss.d_year,
    ss.total_sales,
    ss.total_orders,
    ss.total_customers,
    ds.cd_gender,
    ds.cd_marital_status,
    ds.total_customers AS demographic_customers,
    ds.total_sales AS demographic_sales
FROM 
    sales_summary ss
LEFT JOIN 
    demographics_summary ds ON ss.total_customers = ds.total_customers
ORDER BY 
    ss.d_year DESC, ss.total_sales DESC;
