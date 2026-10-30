
WITH AddressDetails AS (
    SELECT
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(', Suite ', ca_suite_number) ELSE '' END) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM customer_address
),
DemographicDetails AS (
    SELECT
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count,
        cd_dep_employed_count,
        cd_dep_college_count
    FROM customer_demographics
),
FullCustomerDetails AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_country,
        CASE 
            WHEN d.cd_gender = 'M' THEN 'Mr. ' 
            WHEN d.cd_gender = 'F' THEN 'Ms. ' 
            ELSE '' 
        END AS salutation,
        a.full_address,
        a.ca_city,
        a.ca_state,
        a.ca_zip,
        a.ca_country
    FROM customer c 
    JOIN AddressDetails a ON c.c_current_addr_sk = a.ca_address_sk
    JOIN DemographicDetails d ON c.c_current_cdemo_sk = d.cd_demo_sk
),
PurchaseSummary AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_spending,
        COUNT(ws.ws_order_number) AS total_orders
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_id
)
SELECT
    f.c_customer_id,
    f.salutation,
    f.c_first_name,
    f.c_last_name,
    f.full_address,
    f.ca_city,
    f.ca_state,
    f.ca_zip,
    f.ca_country,
    COALESCE(p.total_spending, 0) AS total_spending,
    COALESCE(p.total_orders, 0) AS total_orders
FROM FullCustomerDetails f
LEFT JOIN PurchaseSummary p ON f.c_customer_id = p.c_customer_id
WHERE f.c_birth_country = 'USA'
ORDER BY f.c_last_name, f.c_first_name;
