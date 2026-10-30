
WITH sales_summary AS (
    SELECT 
        ws_bill_customer_sk AS customer_id,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        COUNT(ws_order_number) AS total_orders,
        AVG(ws_net_paid_inc_tax) AS avg_order_value,
        MAX(ws_net_paid_inc_tax) AS max_order_value
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_bill_customer_sk
),
customer_details AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ss.total_sales,
        ss.total_orders,
        ss.avg_order_value,
        ss.max_order_value
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        sales_summary ss ON c.c_customer_sk = ss.customer_id
)
SELECT 
    cd.c_customer_id,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cd.total_sales,
    cd.total_orders,
    cd.avg_order_value,
    cd.max_order_value,
    RANK() OVER (ORDER BY cd.total_sales DESC) AS sales_rank
FROM 
    customer_details cd
WHERE 
    cd.total_sales > 1000
ORDER BY 
    cd.total_sales DESC
LIMIT 100;
