WITH address_data AS (
    SELECT 
        ca_address_id,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca_suite_number) ELSE '' END) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
demo_data AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_credit_rating,
        cd_dep_count,
        cd_purchase_estimate,
        CASE 
            WHEN cd_gender = 'M' AND cd_marital_status = 'M' THEN 'Married Male'
            WHEN cd_gender = 'F' AND cd_marital_status = 'M' THEN 'Married Female'
            WHEN cd_gender = 'M' AND cd_marital_status = 'S' THEN 'Single Male'
            WHEN cd_gender = 'F' AND cd_marital_status = 'S' THEN 'Single Female'
            ELSE 'Other'
        END AS demographic_group
    FROM 
        customer_demographics
),
sales_data AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2450000 AND 2450100  
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    a.ca_address_id,
    a.full_address,
    d.demographic_group,
    COALESCE(s.total_sales, 0) AS total_sales,
    COALESCE(s.order_count, 0) AS order_count,
    CASE 
        WHEN COALESCE(s.total_sales, 0) > 1000 THEN 'High Value'
        WHEN COALESCE(s.total_sales, 0) BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM 
    address_data a
JOIN 
    customer c ON a.ca_address_id = c.c_customer_id
JOIN 
    demo_data d ON c.c_current_cdemo_sk = d.cd_demo_sk
LEFT JOIN 
    sales_data s ON c.c_customer_sk = s.ws_bill_customer_sk
WHERE 
    a.ca_state = 'NY' AND d.cd_education_status LIKE '%Graduate%'
ORDER BY 
    total_sales DESC
LIMIT 100;