
WITH processed_addresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_city, ', ', ca_state, ' ', ca_zip) AS full_address,
        LENGTH(ca_street_name) AS street_name_length,
        LENGTH(ca_city) AS city_length,
        LENGTH(ca_state) AS state_length,
        LENGTH(ca_zip) AS zip_length,
        (CASE 
            WHEN ca_country = 'USA' THEN 'Domestic'
            ELSE 'International'
        END) AS address_type
    FROM 
        customer_address
),
customer_information AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        c.c_email_address,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        pa.full_address,
        pa.street_name_length,
        pa.city_length,
        pa.state_length,
        pa.zip_length,
        pa.address_type
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        processed_addresses pa ON c.c_current_addr_sk = pa.ca_address_sk
),
date_filter AS (
    SELECT 
        d_date_sk
    FROM 
        date_dim
    WHERE 
        d_year = 2023 AND d_month_seq IN (1, 2, 3) 
),
sales_data AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (SELECT d_date_sk FROM date_filter)
    GROUP BY 
        ws_bill_customer_sk
)

SELECT 
    ci.full_name,
    ci.c_email_address,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_purchase_estimate,
    ci.cd_credit_rating,
    sa.total_sales,
    sa.order_count,
    ci.full_address,
    ci.street_name_length,
    ci.city_length,
    ci.state_length,
    ci.zip_length,
    ci.address_type
FROM 
    customer_information ci
LEFT JOIN 
    sales_data sa ON ci.c_customer_sk = sa.ws_bill_customer_sk
WHERE 
    ci.cd_marital_status = 'M' 
ORDER BY 
    sa.total_sales DESC
LIMIT 100;
