
WITH ProcessedAddresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        TRIM(UPPER(ca_city)) AS standardized_city,
        CONCAT(ca_street_number, ' ', ca_street_name) AS street_info,
        ca_state,
        ca_zip
    FROM 
        customer_address
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count
    FROM 
        customer_demographics
    WHERE 
        cd_purchase_estimate > 1000
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(*) AS total_web_sales,
        SUM(ws_sales_price) AS total_revenue
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2458518 AND 2458548
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    ca.full_address,
    ca.standardized_city,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    'Q1' AS quarter,
    sd.total_web_sales,
    sd.total_revenue
FROM 
    ProcessedAddresses ca
JOIN 
    customer c ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    SalesData sd ON c.c_customer_sk = sd.ws_bill_customer_sk
WHERE 
    ca.ca_state = 'NY'
ORDER BY 
    total_revenue DESC
LIMIT 50;
