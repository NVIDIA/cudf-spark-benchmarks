
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca_suite_number) ELSE '' END) AS FullAddress,
        ca_city,
        ca_state,
        REPLACE(ca_zip, '-', '') AS CleanedZip
    FROM 
        customer_address 
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        UPPER(cd_education_status) AS EducationStatus,
        cd_purchase_estimate,
        cd_credit_rating,
        CONCAT(cd_dep_count, ' dependents') AS DependentsInfo
    FROM 
        customer_demographics 
),
SalesAnalysis AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS TotalNetProfit,
        COUNT(DISTINCT ws_order_number) AS OrderCount,
        MAX(ws_sales_price) AS HighestSalePrice
    FROM 
        web_sales 
    WHERE 
        ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    ad.FullAddress,
    ad.ca_city,
    ad.ca_state,
    cd.EducationStatus,
    cd.DependentsInfo,
    sa.TotalNetProfit,
    sa.OrderCount,
    sa.HighestSalePrice
FROM 
    customer AS c
JOIN 
    AddressDetails AS ad ON c.c_current_addr_sk = ad.ca_address_sk
JOIN 
    CustomerDemographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    SalesAnalysis AS sa ON c.c_customer_sk = sa.ws_bill_customer_sk
WHERE 
    cd.cd_gender = 'F' AND
    sa.TotalNetProfit > 5000
ORDER BY 
    sa.TotalNetProfit DESC;
