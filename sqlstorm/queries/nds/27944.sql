
WITH AddressInfo AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state
    FROM 
        customer_address
),
CustomerInfo AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesSummary AS (
    SELECT 
        ss_customer_sk,
        SUM(ss_net_paid) AS total_spent,
        COUNT(DISTINCT ss_ticket_number) AS total_transactions
    FROM 
        store_sales
    GROUP BY 
        ss_customer_sk
)
SELECT 
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ai.full_address,
    ai.ca_city,
    ai.ca_state,
    COALESCE(ss.total_spent, 0) AS total_spent,
    COALESCE(ss.total_transactions, 0) AS total_transactions
FROM 
    CustomerInfo ci
JOIN 
    customer_address ca ON ci.c_customer_sk = ca.ca_address_sk
JOIN 
    AddressInfo ai ON ca.ca_address_sk = ai.ca_address_sk
LEFT JOIN 
    SalesSummary ss ON ci.c_customer_sk = ss.ss_customer_sk
WHERE 
    ai.ca_state = 'CA' AND 
    ci.cd_purchase_estimate > 1000
ORDER BY 
    total_spent DESC
LIMIT 100;
