
WITH sales_summary AS (
    SELECT 
        ws_sold_date_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_bill_customer_sk) AS customer_count,
        COUNT(DISTINCT ws_order_number) AS order_count,
        AVG(ws_net_profit) AS avg_net_profit,
        SUM(ws_net_paid_inc_tax) AS total_revenue
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 
            (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 
            AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_sold_date_sk
), 
customer_details AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        COUNT(DISTINCT c_customer_sk) AS num_customers,
        SUM(CASE WHEN c_birth_year IS NOT NULL THEN 1 ELSE 0 END) AS age_verified_count
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd_demo_sk, cd_gender, cd_marital_status
) 
SELECT 
    ds.d_date AS sales_date,
    ss.total_sales,
    ss.customer_count,
    ss.order_count,
    ss.avg_net_profit,
    ss.total_revenue,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.num_customers,
    cd.age_verified_count
FROM 
    sales_summary ss
JOIN 
    date_dim ds ON ss.ws_sold_date_sk = ds.d_date_sk
JOIN 
    customer_details cd ON cd.num_customers > 0
ORDER BY 
    ds.d_date
LIMIT 100;
