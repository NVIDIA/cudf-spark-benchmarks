
WITH AddressParts AS (
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
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        c.c_email_address,
        cd.cd_gender,
        cd.cd_marital_status
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesInfo AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
),
Ranks AS (
    SELECT 
        ci.full_name,
        ci.c_email_address,
        si.total_sales,
        si.total_orders,
        ROW_NUMBER() OVER (PARTITION BY ap.ca_state ORDER BY si.total_sales DESC) AS sales_rank,
        ap.ca_state
    FROM CustomerInfo ci
    JOIN SalesInfo si ON ci.c_customer_sk = si.ws_bill_customer_sk
    JOIN AddressParts ap ON ci.c_customer_sk = ap.ca_address_sk
)
SELECT
    full_name,
    c_email_address,
    total_sales,
    total_orders,
    sales_rank,
    ca_state
FROM Ranks
WHERE sales_rank <= 10
ORDER BY ca_state, sales_rank;
