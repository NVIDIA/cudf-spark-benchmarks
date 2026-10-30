
WITH sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_net_paid) AS total_revenue,
        SUM(ws_quantity) AS total_quantity,
        AVG(ws_net_paid) AS avg_order_value
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01')
        AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY 
        ws_bill_customer_sk
),
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cs.total_orders,
        cs.total_revenue,
        cs.total_quantity,
        cs.avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        sales_summary cs ON c.c_customer_sk = cs.ws_bill_customer_sk
)
SELECT 
    cu.c_first_name,
    cu.c_last_name,
    cu.cd_gender,
    cu.cd_marital_status,
    cu.cd_education_status,
    cu.total_orders,
    cu.total_revenue,
    cu.total_quantity,
    cu.avg_order_value,
    COUNT(ds.ws_order_number) AS distinct_order_count
FROM 
    customer_summary cu
LEFT JOIN 
    web_sales ds ON cu.c_customer_sk = ds.ws_bill_customer_sk
GROUP BY 
    cu.c_first_name, cu.c_last_name, cu.cd_gender, cu.cd_marital_status, 
    cu.cd_education_status, cu.total_orders, cu.total_revenue, 
    cu.total_quantity, cu.avg_order_value
ORDER BY 
    total_revenue DESC
LIMIT 100;
