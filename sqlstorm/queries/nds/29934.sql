
WITH ConcatenatedAddresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE WHEN ca_suite_number IS NOT NULL AND ca_suite_number <> '' 
                    THEN CONCAT(', Suite ', ca_suite_number) 
                    ELSE '' END,
               ', ', ca_city, ', ', ca_state, ' ', ca_zip) AS full_address
    FROM customer_address
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        COALESCE(cd.cd_gender, 'Unknown') AS gender,
        COALESCE(cd.cd_marital_status, 'U') AS marital_status,
        cad.full_address
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN ConcatenatedAddresses cad ON c.c_current_addr_sk = cad.ca_address_sk
),
SalesInformation AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS total_orders
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
)
SELECT 
    cd.full_name,
    cd.gender,
    cd.marital_status,
    cd.full_address,
    COALESCE(si.total_profit, 0) AS total_profit,
    COALESCE(si.total_orders, 0) AS total_orders
FROM CustomerDetails cd
LEFT JOIN SalesInformation si ON cd.c_customer_sk = si.ws_bill_customer_sk
ORDER BY total_profit DESC, cd.full_name;
