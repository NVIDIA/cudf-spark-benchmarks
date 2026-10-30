
WITH AddressDetails AS (
    SELECT 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_address_sk
    FROM 
        customer_address
),
Demographics AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_demo_sk
    FROM 
        customer_demographics
),
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_spent,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ad.full_address,
        ad.ca_city,
        ad.ca_state,
        ad.ca_zip,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status,
        d.cd_purchase_estimate,
        d.cd_credit_rating,
        ss.total_spent,
        ss.total_orders
    FROM 
        customer c
    JOIN 
        AddressDetails ad ON c.c_current_addr_sk = ad.ca_address_sk
    JOIN 
        Demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
    LEFT JOIN 
        SalesSummary ss ON c.c_customer_sk = ss.ws_bill_customer_sk
)
SELECT 
    COALESCE(full_name, 'Unknown Customer') AS customer_name,
    COALESCE(full_address, 'No Address') AS customer_address,
    ca_city,
    ca_state,
    ca_zip,
    COALESCE(cd_gender, 'N/A') AS gender,
    COALESCE(cd_marital_status, 'N/A') AS marital_status,
    COALESCE(cd_education_status, 'N/A') AS education_status,
    COALESCE(total_spent, 0) AS total_spent,
    COALESCE(total_orders, 0) AS total_orders
FROM 
    CustomerInfo
WHERE 
    COALESCE(total_spent, 0) > 1000
ORDER BY 
    total_spent DESC
LIMIT 10;
