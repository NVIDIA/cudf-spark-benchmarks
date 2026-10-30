
WITH AddressInfo AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_country
    FROM customer_address
), 
CustomerInfo AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_marital_status,
        cd_gender,
        cd_purchase_estimate
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), 
SalesStats AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS number_of_orders,
        AVG(ws_sales_price) AS average_order_value
    FROM web_sales
    GROUP BY ws_bill_customer_sk
)
SELECT 
    ci.full_name,
    ai.full_address,
    ai.ca_city,
    ai.ca_state,
    ai.ca_country,
    ss.total_sales,
    ss.number_of_orders,
    ss.average_order_value
FROM CustomerInfo ci
JOIN AddressInfo ai ON ci.c_customer_sk = ai.ca_address_sk
JOIN SalesStats ss ON ci.c_customer_sk = ss.ws_bill_customer_sk
WHERE ss.total_sales > 500
ORDER BY ss.total_sales DESC;
