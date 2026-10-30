WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
        COALESCE(CONCAT(' Suite ', ca_suite_number), '')) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),

CustomerDetails AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count,
        cd_dep_employed_count,
        cd_dep_college_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),

SalesSummary AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)

SELECT 
    CONCAT(cd.c_first_name, ' ', cd.c_last_name) AS customer_name,
    ad.full_address,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    ss.total_profit,
    ss.total_orders
FROM 
    CustomerDetails cd
JOIN 
    AddressDetails ad ON ad.ca_address_sk = cd.c_customer_sk  
LEFT JOIN 
    SalesSummary ss ON cd.c_customer_sk = ss.customer_sk
WHERE 
    cd.cd_gender = 'F'
    AND ss.total_profit > 1000
ORDER BY 
    ss.total_profit DESC
LIMIT 10;