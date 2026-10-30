
WITH AddressInfo AS (
    SELECT 
        ca_address_sk,
        CONCAT_WS(', ', ca_street_number, ca_street_name, ca_street_type, ca_suite_number, ca_city, ca_state, ca_zip, ca_country) AS full_address
    FROM customer_address
),
CustomerInfo AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_salutation, ' ', c_first_name, ' ', c_last_name) AS full_name,
        c_email_address,
        ca_address_sk
    FROM customer
    JOIN AddressInfo ON customer.c_current_addr_sk = AddressInfo.ca_address_sk
),
WebSalesInfo AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM web_sales
    GROUP BY ws_bill_customer_sk
)
SELECT 
    ci.full_name,
    ci.c_email_address,
    ai.full_address,
    COALESCE(wsi.total_net_profit, 0) AS total_net_profit,
    COALESCE(wsi.total_orders, 0) AS total_orders
FROM CustomerInfo ci
JOIN AddressInfo ai ON ci.ca_address_sk = ai.ca_address_sk
LEFT JOIN WebSalesInfo wsi ON ci.c_customer_sk = wsi.ws_bill_customer_sk
ORDER BY total_net_profit DESC, ci.full_name;
