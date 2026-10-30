
WITH AddressData AS (
    SELECT 
        ca_address_sk,
        ca_city,
        ca_state,
        ca_country,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address
    FROM 
        customer_address
),
CustomerData AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        cd_gender,
        cd_marital_status,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_credit_rating
    FROM 
        customer 
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),
SalesData AS (
    SELECT 
        ws_ship_customer_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales 
    GROUP BY 
        ws_ship_customer_sk
),
CombinedData AS (
    SELECT 
        c.full_name,
        a.ca_city,
        a.ca_state,
        a.ca_country,
        a.full_address,
        s.total_sales,
        s.total_orders
    FROM 
        CustomerData c
    JOIN 
        AddressData a ON c.c_customer_sk = a.ca_address_sk
    LEFT JOIN 
        SalesData s ON c.c_customer_sk = s.ws_ship_customer_sk
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    ca_country,
    full_address,
    COALESCE(total_sales, 0) AS total_sales,
    COALESCE(total_orders, 0) AS total_orders,
    CASE 
        WHEN total_sales > 1000 THEN 'High Value Customer'
        WHEN total_sales BETWEEN 500 AND 1000 THEN 'Mid Value Customer'
        ELSE 'Low Value Customer' 
    END AS customer_value_category
FROM 
    CombinedData
ORDER BY 
    total_sales DESC
LIMIT 50;
