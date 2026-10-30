
WITH AddressInfo AS (
    SELECT 
        ca_address_sk,
        CONCAT_WS(' ', ca_street_number, ca_street_name, ca_street_type, COALESCE(ca_suite_number, '')) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM customer_address
),
CustomerInfo AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        ci.full_address,
        ci.ca_city,
        ci.ca_state,
        ci.ca_zip
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN AddressInfo ci ON c.c_current_addr_sk = ci.ca_address_sk
),
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders 
    FROM web_sales ws
    JOIN CustomerInfo ci ON ws.ws_bill_customer_sk = ci.c_customer_sk
    GROUP BY ws.ws_item_sk
),
FinalOutput AS (
    SELECT 
        ci.full_name,
        ci.cd_gender,
        ci.cd_marital_status,
        sd.total_quantity,
        sd.total_sales,
        sd.total_orders 
    FROM CustomerInfo ci
    JOIN SalesData sd ON sd.ws_item_sk = ci.c_customer_sk
    WHERE ci.cd_gender = 'F'
)
SELECT 
    full_name,
    cd_gender,
    cd_marital_status,
    total_quantity,
    ROUND(total_sales, 2) AS formatted_sales,
    total_orders
FROM FinalOutput
ORDER BY total_sales DESC
LIMIT 10;
