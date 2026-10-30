
WITH AddressInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS full_name,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesData AS (
    SELECT
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM web_sales ws
    JOIN AddressInfo c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_sk
)
SELECT 
    a.full_name,
    a.full_address,
    a.ca_city,
    a.ca_state,
    a.ca_country,
    COALESCE(s.total_sales, 0) AS total_sales,
    COALESCE(s.order_count, 0) AS order_count,
    CASE
        WHEN COALESCE(s.total_sales, 0) = 0 THEN 'No Purchases'
        WHEN COALESCE(s.order_count, 0) > 5 THEN 'Frequent Buyer'
        ELSE 'Occasional Buyer'
    END AS buyer_type
FROM AddressInfo a
LEFT JOIN SalesData s ON a.c_customer_sk = s.c_customer_sk
WHERE a.ca_state = 'CA'
ORDER BY total_sales DESC
LIMIT 50;
