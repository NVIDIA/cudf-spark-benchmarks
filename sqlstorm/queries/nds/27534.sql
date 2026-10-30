
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        c.c_email_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        cd.cd_gender = 'F' 
        AND cd.cd_marital_status = 'M'
),
item_order_summary AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_ext_discount_amt) AS total_discount,
        SUM(ws_ext_tax) AS total_tax
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
final_benchmark AS (
    SELECT 
        ci.full_name,
        ci.c_email_address,
        ci.ca_city,
        ci.ca_state,
        oi.total_orders,
        oi.total_sales,
        oi.total_discount,
        oi.total_tax,
        CASE 
            WHEN oi.total_sales > 1000 THEN 'High Value'
            WHEN oi.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value
    FROM 
        customer_info ci
    LEFT JOIN 
        item_order_summary oi ON ci.c_customer_sk = oi.ws_bill_customer_sk
)
SELECT 
    *
FROM 
    final_benchmark
WHERE 
    customer_value = 'High Value'
ORDER BY 
    total_sales DESC;
