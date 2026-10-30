WITH address_details AS (
    SELECT 
        ca_address_id,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        CONCAT(ca_state, ' ', ca_zip) AS state_zip
    FROM 
        customer_address
),
demographic_details AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating
    FROM 
        customer_demographics
),
customer_details AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        c_email_address,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name
    FROM 
        customer
),
sales_details AS (
    SELECT 
        ws_item_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
enhanced_report AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.full_address,
        ca.ca_city,
        ca.state_zip,
        SUM(sd.total_sales) AS total_sales_value,
        COUNT(sd.total_orders) AS total_transactions
    FROM 
        demographic_details cd
    JOIN 
        customer_details cc ON cc.c_customer_sk = cd.cd_demo_sk
    JOIN 
        address_details ca ON ca.ca_address_id = cc.c_email_address 
    LEFT JOIN 
        sales_details sd ON sd.ws_item_sk = cc.c_customer_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, ca.full_address, ca.ca_city, ca.state_zip
)
SELECT 
    * 
FROM 
    enhanced_report
WHERE 
    total_sales_value > 1000 AND cd_gender = 'M'
ORDER BY 
    total_sales_value DESC
LIMIT 10;