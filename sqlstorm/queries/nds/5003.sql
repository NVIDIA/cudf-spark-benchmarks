
WITH aggregated_sales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales_price,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 20230101 AND 20231231
    GROUP BY 
        ws_bill_customer_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        addr.ca_city,
        addr.ca_state
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address addr ON c.c_current_addr_sk = addr.ca_address_sk
),
high_value_customers AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        ci.cd_purchase_estimate,
        ci.ca_city,
        ci.ca_state,
        asales.total_quantity,
        asales.total_sales_price,
        asales.order_count
    FROM 
        customer_info ci
    JOIN 
        aggregated_sales asales ON ci.c_customer_sk = asales.ws_bill_customer_sk
    WHERE 
        asales.total_quantity > 100 
        AND asales.total_sales_price > 1000
    ORDER BY 
        asales.total_sales_price DESC
)
SELECT 
    hvc.c_first_name, 
    hvc.c_last_name, 
    hvc.cd_gender, 
    hvc.cd_marital_status, 
    hvc.cd_education_status, 
    hvc.total_quantity, 
    hvc.total_sales_price, 
    hvc.order_count, 
    hvc.ca_city, 
    hvc.ca_state 
FROM 
    high_value_customers hvc
LIMIT 100;
