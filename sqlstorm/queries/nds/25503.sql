
WITH AddressData AS (
    SELECT
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM customer_address
    WHERE ca_country = 'USA'
), CustomerData AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_spent,
        COUNT(ws_order_number) AS order_count
    FROM web_sales
    GROUP BY ws_bill_customer_sk
), CombinedData AS (
    SELECT 
        c.full_name,
        c.cd_gender,
        c.cd_marital_status,
        c.cd_education_status,
        a.full_address,
        a.ca_city,
        a.ca_state,
        a.ca_zip,
        COALESCE(s.total_spent, 0) AS total_spent,
        COALESCE(s.order_count, 0) AS order_count
    FROM CustomerData c
    JOIN AddressData a ON c.c_customer_sk = a.ca_address_sk
    LEFT JOIN SalesData s ON c.c_customer_sk = s.ws_bill_customer_sk
)
SELECT 
    full_name,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    full_address,
    ca_city,
    ca_state,
    ca_zip,
    total_spent,
    order_count,
    CASE 
        WHEN total_spent = 0 THEN 'No Purchases'
        WHEN total_spent < 100 THEN 'Low Spender'
        WHEN total_spent BETWEEN 100 AND 500 THEN 'Medium Spender'
        ELSE 'High Spender'
    END AS spending_category
FROM CombinedData
ORDER BY total_spent DESC, full_name;
