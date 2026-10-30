
WITH AddressDetails AS (
    SELECT 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country,
        ca_address_sk
    FROM 
        customer_address
),
DemographicDetails AS (
    SELECT 
        cd_demo_sk,
        cd_gender, 
        cd_marital_status, 
        cd_education_status
    FROM 
        customer_demographics
),
SalesSummary AS (
    SELECT 
        SUM(ss_net_paid) AS total_sales,
        COUNT(DISTINCT ss_customer_sk) AS unique_customers,
        AVG(ss_net_profit) AS avg_net_profit
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk = (SELECT MAX(ss_sold_date_sk) FROM store_sales)
)
SELECT 
    ad.full_address,
    ad.ca_city,
    ad.ca_state,
    ad.ca_zip,
    ad.ca_country,
    dd.cd_gender,
    dd.cd_marital_status,
    dd.cd_education_status,
    ss.total_sales,
    ss.unique_customers,
    ss.avg_net_profit
FROM 
    AddressDetails ad
JOIN 
    customer c ON ad.ca_address_sk = c.c_current_addr_sk
JOIN 
    DemographicDetails dd ON c.c_current_cdemo_sk = dd.cd_demo_sk
CROSS JOIN 
    SalesSummary ss
WHERE 
    ad.ca_state = 'NY'
GROUP BY 
    ad.full_address,
    ad.ca_city,
    ad.ca_state,
    ad.ca_zip,
    ad.ca_country,
    dd.cd_gender,
    dd.cd_marital_status,
    dd.cd_education_status,
    ss.total_sales,
    ss.unique_customers,
    ss.avg_net_profit
ORDER BY 
    ss.total_sales DESC
LIMIT 10;
