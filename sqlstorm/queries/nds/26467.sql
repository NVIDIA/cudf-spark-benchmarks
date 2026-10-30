
WITH CustomerAddress AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city AS city,
        ca_state AS state,
        ca_zip AS zip
    FROM customer_address
),
CustomerData AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
FrequentCustomers AS (
    SELECT 
        cd.c_customer_sk,
        COUNT(ws.ws_order_number) AS order_count
    FROM web_sales ws
    JOIN CustomerData cd ON ws.ws_bill_customer_sk = cd.c_customer_sk
    GROUP BY cd.c_customer_sk
    HAVING COUNT(ws.ws_order_number) > 5
)
SELECT 
    cd.full_name,
    fc.order_count,
    ca.full_address,
    ca.city,
    ca.state,
    ca.zip
FROM FrequentCustomers fc
JOIN CustomerAddress ca ON fc.c_customer_sk = ca.ca_address_sk
JOIN CustomerData cd ON fc.c_customer_sk = cd.c_customer_sk
ORDER BY fc.order_count DESC, cd.full_name;
