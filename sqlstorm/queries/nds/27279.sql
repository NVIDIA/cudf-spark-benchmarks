
WITH AddressInfo AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               COALESCE(ca_suite_number, '')) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
DemographicInfo AS (
    SELECT 
        cd_demo_sk,
        CASE 
            WHEN cd_gender = 'M' THEN 'Male' 
            WHEN cd_gender = 'F' THEN 'Female' 
            ELSE 'Non-binary/Unknown' 
        END AS gender,
        cd_marital_status AS marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating
    FROM 
        customer_demographics
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk, 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        c.c_email_address,
        a.full_address,
        d.gender,
        d.marital_status,
        d.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        AddressInfo a ON c.c_current_addr_sk = a.ca_address_sk
    JOIN 
        DemographicInfo d ON c.c_current_cdemo_sk = d.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid_inc_tax) AS total_spent,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    c.customer_name,
    c.c_email_address,
    c.full_address,
    c.gender,
    c.marital_status,
    s.total_spent,
    s.total_orders
FROM 
    CustomerDetails c
LEFT JOIN 
    SalesData s ON c.c_customer_sk = s.ws_bill_customer_sk
ORDER BY 
    total_spent DESC, customer_name;
