
WITH Address_Analysis AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        LENGTH(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS address_length,
        TRIM(ca_city) AS trimmed_city,
        UPPER(ca_state) AS upper_state
    FROM 
        customer_address
    WHERE 
        ca_city IS NOT NULL 
    AND 
        ca_state IS NOT NULL
), 
Customer_Analysis AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        LENGTH(CONCAT(c_first_name, ' ', c_last_name)) AS name_length
    FROM 
        customer 
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
), 
Sales_Analysis AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_coupon_amt) AS total_coupons,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales 
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    ca.full_address,
    ca.address_length,
    ca.trimmed_city,
    ca.upper_state,
    cu.full_name,
    cu.cd_gender,
    cu.cd_marital_status,
    sa.total_sales,
    sa.total_coupons,
    sa.total_orders
FROM 
    Address_Analysis ca
JOIN 
    Customer_Analysis cu ON ca.ca_address_sk = cu.c_customer_sk
LEFT JOIN 
    Sales_Analysis sa ON cu.c_customer_sk = sa.ws_bill_customer_sk
ORDER BY 
    sa.total_sales DESC, 
    cu.name_length ASC
LIMIT 100;
