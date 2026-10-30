
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(TRIM(ca_street_number), ' ', TRIM(ca_street_name), ' ', TRIM(ca_street_type), 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', TRIM(ca_suite_number)) ELSE '' END) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM 
        customer_address
),
DemographicDetails AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating
    FROM 
        customer_demographics
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(TRIM(c.c_first_name), ' ', TRIM(c.c_last_name)) AS full_name,
        c.c_preferred_cust_flag,
        cd.cd_gender,
        cd.cd_marital_status,
        ad.full_address,
        ad.ca_city,
        ad.ca_state,
        ad.ca_zip
    FROM 
        customer c
    LEFT JOIN 
        DemographicDetails cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        AddressDetails ad ON c.c_current_addr_sk = ad.ca_address_sk
),
SalesSummary AS (
    SELECT 
        cs_bill_customer_sk AS customer_sk,
        SUM(cs_net_profit) AS total_profit,
        COUNT(cs_order_number) AS total_orders
    FROM 
        catalog_sales
    GROUP BY 
        cs_bill_customer_sk
)
SELECT 
    cd.full_name,
    cd.full_address,
    cd.ca_city,
    cd.ca_state,
    cd.ca_zip,
    COALESCE(ss.total_profit, 0) AS total_profit,
    COALESCE(ss.total_orders, 0) AS total_orders
FROM 
    CustomerDetails cd
LEFT JOIN 
    SalesSummary ss ON cd.c_customer_sk = ss.customer_sk
WHERE 
    cd.cd_gender = 'F' AND 
    cd.cd_marital_status = 'M'
ORDER BY 
    total_profit DESC
LIMIT 50;
