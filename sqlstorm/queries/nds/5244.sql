
WITH sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_net_profit) AS total_net_profit,
        SUM(ws_ext_sales_price) AS total_sales,
        AVG(ws_net_paid_inc_tax) AS avg_net_paid
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY 
        ws_bill_customer_sk
), 
demographic_info AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate
    FROM 
        customer_demographics 
    WHERE 
        cd_credit_rating IN ('Excellent', 'Good')
), 
customer_info AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_year,
        c.c_login,
        c.c_email_address,
        ci.total_orders,
        ci.total_net_profit,
        ci.total_sales,
        ci.avg_net_paid,
        di.cd_gender,
        di.cd_marital_status,
        di.cd_education_status,
        di.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        sales_summary ci ON c.c_customer_sk = ci.ws_bill_customer_sk
    JOIN 
        demographic_info di ON c.c_current_cdemo_sk = di.cd_demo_sk
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    c.c_birth_year,
    c.c_login,
    c.c_email_address,
    c.total_orders,
    c.total_net_profit,
    c.total_sales,
    c.avg_net_paid,
    d.ca_city,
    d.ca_state
FROM 
    customer_info c
LEFT JOIN 
    customer_address d ON c.c_customer_id = d.ca_address_id
ORDER BY 
    c.total_net_profit DESC
LIMIT 10;
