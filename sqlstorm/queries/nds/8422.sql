
WITH daily_sales AS (
    SELECT 
        d.d_date AS sale_date,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid_inc_tax) AS avg_order_value
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_date
),
top_customers AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_id
    ORDER BY 
        total_net_profit DESC
    LIMIT 10
),
customer_demographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(DISTINCT c.c_customer_sk) AS num_customers,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
)
SELECT 
    ds.sale_date,
    ds.total_quantity,
    ds.total_net_profit,
    ds.total_orders,
    ds.avg_order_value,
    tc.c_customer_id AS top_customer_id,
    tc.total_net_profit AS top_customer_profit,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cd.num_customers,
    cd.avg_purchase_estimate
FROM 
    daily_sales ds
LEFT JOIN 
    top_customers tc ON ds.sale_date = (SELECT MAX(sale_date) FROM daily_sales)
LEFT JOIN 
    customer_demographics cd ON cd.num_customers > 0
ORDER BY 
    ds.sale_date DESC, ds.total_net_profit DESC;
