
WITH processed_addresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        SUBSTRING(ca_zip, 1, 5) AS zip_prefix
    FROM 
        customer_address
),
customer_details AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        CASE 
            WHEN cd.cd_dep_count > 0 THEN 'Has Dependents' 
            ELSE 'No Dependents' 
        END AS dependent_status
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    ca.ca_address_sk,
    ca.full_address,
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    cd.dependent_status,
    ss.total_orders,
    ss.total_sales,
    CASE 
        WHEN ss.total_sales > 1000 THEN 'High Value Customer'
        WHEN ss.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer' 
    END AS customer_value_category
FROM 
    processed_addresses ca
LEFT JOIN 
    customer_details cd ON cd.c_customer_sk = ca.ca_address_sk
LEFT JOIN 
    sales_summary ss ON ss.ws_bill_customer_sk = ca.ca_address_sk
WHERE 
    ca.zip_prefix = '12345'
ORDER BY 
    ca.ca_address_sk;
