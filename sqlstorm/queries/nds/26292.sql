
WITH FilteredCustomers AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_email_address, c_current_cdemo_sk, c_current_addr_sk
    FROM customer
    WHERE c_birth_year BETWEEN 1980 AND 1995
),
Demographics AS (
    SELECT cd_demo_sk, cd_gender, cd_marital_status, cd_education_status
    FROM customer_demographics
),
Address AS (
    SELECT ca_address_sk, ca_city, ca_state, ca_zip
    FROM customer_address
),
CustomerInfo AS (
    SELECT 
        f.c_customer_sk,
        f.c_first_name,
        f.c_last_name,
        f.c_email_address,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status,
        a.ca_city,
        a.ca_state,
        a.ca_zip
    FROM FilteredCustomers f
    JOIN Demographics d ON f.c_current_cdemo_sk = d.cd_demo_sk
    JOIN Address a ON f.c_current_addr_sk = a.ca_address_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk, 
        SUM(ws_net_profit) AS total_profit,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_quantity) AS total_quantity
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
FinalReport AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        c.ca_city,
        c.ca_state,
        c.ca_zip,
        s.total_profit,
        s.total_orders,
        s.total_quantity
    FROM CustomerInfo c
    LEFT JOIN SalesData s ON c.c_customer_sk = s.ws_bill_customer_sk
)
SELECT 
    CONCAT(c_first_name, ' ', c_last_name) AS full_name,
    c_email_address,
    ca_city,
    ca_state,
    ca_zip,
    COALESCE(total_profit, 0) AS total_profit,
    COALESCE(total_orders, 0) AS total_orders,
    COALESCE(total_quantity, 0) AS total_quantity
FROM FinalReport
ORDER BY total_profit DESC, total_orders DESC
LIMIT 100;
