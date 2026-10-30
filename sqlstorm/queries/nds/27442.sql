
WITH AddressData AS (
    SELECT 
        ca_address_sk,
        TRIM(CONCAT_WS(' ', ca_street_number, ca_street_name, ca_street_type, ca_suite_number)) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
Demographics AS (
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
    FROM 
        customer_demographics
),
CustomerData AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        a.full_address,
        a.ca_city,
        a.ca_state,
        a.ca_zip,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status
    FROM 
        customer c 
    JOIN 
        AddressData a ON c.c_current_addr_sk = a.ca_address_sk
    JOIN 
        Demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_spent,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
FinalCustomerReport AS (
    SELECT 
        cd.c_customer_sk,
        cd.full_name,
        cd.full_address,
        cd.ca_city,
        cd.ca_state,
        cd.ca_zip,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COALESCE(sd.total_spent, 0) AS total_spent,
        COALESCE(sd.order_count, 0) AS order_count
    FROM 
        CustomerData cd
    LEFT JOIN 
        SalesData sd ON cd.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT 
    *,
    CASE 
        WHEN total_spent > 1000 THEN 'High Value'
        WHEN total_spent BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_classification
FROM 
    FinalCustomerReport
ORDER BY 
    total_spent DESC
LIMIT 50;
