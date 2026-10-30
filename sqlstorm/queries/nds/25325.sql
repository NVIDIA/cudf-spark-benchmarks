
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        TRIM(ca_suite_number) AS suite_number,
        ca_city,
        ca_state,
        UPPER(ca_country) AS country
    FROM 
        customer_address
    WHERE 
        ca_city IS NOT NULL OR ca_state IS NOT NULL
), 
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ad.full_address,
        ad.suite_number,
        ad.ca_city AS city,
        ad.ca_state AS state,
        ad.country
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        AddressDetails ad ON c.c_current_addr_sk = ad.ca_address_sk
), 
PurchaseDetails AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        web_sales ws
    JOIN 
        CustomerDetails c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_sk
)
SELECT 
    cd.full_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    COALESCE(pd.total_spent, 0) AS total_spent,
    CASE
        WHEN COALESCE(pd.total_spent, 0) = 0 THEN 'No Purchases'
        WHEN pd.total_spent < 100 THEN 'Low Spender'
        WHEN pd.total_spent BETWEEN 100 AND 500 THEN 'Medium Spender'
        ELSE 'High Spender'
    END AS spending_category
FROM 
    CustomerDetails cd
LEFT JOIN 
    PurchaseDetails pd ON cd.c_customer_sk = pd.c_customer_sk
ORDER BY 
    cd.full_name;
