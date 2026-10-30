
WITH Address AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        CONCAT(ca_city, ', ', ca_state, ' ', ca_zip) AS location_details
    FROM 
        customer_address
),
Customer AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
Sales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    c.full_name,
    c.cd_gender,
    c.cd_marital_status,
    a.full_address,
    a.location_details,
    COALESCE(s.total_sales, 0) AS total_sales,
    COALESCE(s.order_count, 0) AS order_count
FROM 
    Customer c
JOIN 
    Address a ON c.c_customer_sk = a.ca_address_sk
LEFT JOIN 
    Sales s ON c.c_customer_sk = s.ws_bill_customer_sk
WHERE 
    c.cd_purchase_estimate > 500 AND 
    c.cd_gender = 'F'
GROUP BY 
    c.full_name, 
    c.cd_gender, 
    c.cd_marital_status, 
    a.full_address, 
    a.location_details, 
    s.total_sales, 
    s.order_count
ORDER BY 
    total_sales DESC, 
    c.full_name ASC
LIMIT 100;
