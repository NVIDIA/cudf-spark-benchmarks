
WITH processed_addresses AS (
    SELECT 
        ca_address_sk,
        CONCAT_WS(' ', ca_street_number, ca_street_name, ca_street_type, COALESCE(ca_suite_number, '')) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        UPPER(ca_country) AS country_uppercase
    FROM 
        customer_address
),
customer_demographics_enhanced AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        CASE 
            WHEN cd_purchase_estimate < 1000 THEN 'Low'
            WHEN cd_purchase_estimate BETWEEN 1000 AND 5000 THEN 'Medium'
            ELSE 'High' 
        END AS purchase_category
    FROM 
        customer_demographics
),
sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
final_benchmark AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        da.full_address,
        cd.cd_gender AS gender,
        cd.purchase_category,
        ss.total_sales,
        ss.total_orders
    FROM 
        customer c
    JOIN processed_addresses da ON c.c_current_addr_sk = da.ca_address_sk
    JOIN customer_demographics_enhanced cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN sales_summary ss ON c.c_customer_sk = ss.ws_bill_customer_sk
    WHERE 
        cd.cd_gender = 'F' 
        AND da.ca_state = 'NY'
        AND ss.total_sales > 1000
)
SELECT 
    final_benchmark.*,
    LENGTH(full_address) AS address_length,
    LOWER(c_last_name) AS lower_last_name
FROM 
    final_benchmark
ORDER BY 
    total_sales DESC
LIMIT 100;
