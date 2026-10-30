
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
CustomerFullName AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_salutation, ' ', c_first_name, ' ', c_last_name) AS full_name,
        c_email_address,
        c_current_addr_sk
    FROM 
        customer
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    c.full_name,
    a.full_address,
    a.ca_city,
    a.ca_state,
    a.ca_zip,
    s.total_profit,
    s.total_orders,
    CASE 
        WHEN s.total_profit > 1000 THEN 'High Value Customer'
        WHEN s.total_profit BETWEEN 500 AND 1000 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_value_category
FROM 
    CustomerFullName c
JOIN 
    AddressDetails a ON a.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    SalesData s ON s.ws_bill_customer_sk = c.c_customer_sk
WHERE 
    a.ca_state = 'CA'
ORDER BY 
    s.total_profit DESC, 
    c.full_name;
