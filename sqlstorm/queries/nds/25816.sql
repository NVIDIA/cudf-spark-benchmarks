
WITH AddressParts AS (
    SELECT 
        ca_address_sk, 
        TRIM(ca_street_number || ' ' || ca_street_name || ' ' || ca_street_type || CASE WHEN ca_suite_number IS NOT NULL THEN ' Suite ' || ca_suite_number ELSE '' END) AS Full_Address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM customer_address
), Demographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        TRIM(cd_education_status) AS Education_Status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count,
        cd_dep_employed_count,
        cd_dep_college_count
    FROM customer_demographics
), AggregatedSales AS (
    SELECT 
        ws_bill_cdemo_sk,
        COUNT(*) AS Total_Sales,
        SUM(ws_sales_price) AS Total_Sales_Value,
        AVG(ws_sales_price) AS Average_Sale_Value
    FROM web_sales
    GROUP BY ws_bill_cdemo_sk
)
SELECT 
    a.Full_Address,
    a.ca_city,
    a.ca_state,
    a.ca_zip,
    a.ca_country,
    d.cd_gender,
    d.Education_Status,
    d.cd_purchase_estimate,
    d.cd_credit_rating,
    COALESCE(s.Total_Sales, 0) AS Total_Sales,
    COALESCE(s.Total_Sales_Value, 0) AS Total_Sales_Value,
    COALESCE(s.Average_Sale_Value, 0) AS Average_Sale_Value
FROM AddressParts AS a
JOIN Demographics AS d ON a.ca_address_sk = d.cd_demo_sk
LEFT JOIN AggregatedSales AS s ON d.cd_demo_sk = s.ws_bill_cdemo_sk
WHERE a.ca_city LIKE 'San%' 
AND a.ca_state = 'CA' 
AND d.cd_marital_status = 'M'
ORDER BY Total_Sales_Value DESC
LIMIT 100;
