
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM customer_address
), CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), SalesStatistics AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM web_sales
    GROUP BY ws_bill_customer_sk
)

SELECT 
    c.full_name,
    a.full_address,
    a.ca_city,
    a.ca_state,
    a.ca_zip,
    a.ca_country,
    s.total_quantity,
    s.total_sales,
    s.total_orders,
    CASE 
        WHEN s.total_sales IS NULL THEN 'No Sales'
        WHEN s.total_sales > 1000 THEN 'High Value Customer'
        WHEN s.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_value_segment
FROM CustomerDetails c
JOIN AddressDetails a ON c.c_customer_sk = a.ca_address_sk 
LEFT JOIN SalesStatistics s ON c.c_customer_sk = s.ws_bill_customer_sk
WHERE a.ca_state = 'NY'
ORDER BY s.total_sales DESC NULLS LAST;
