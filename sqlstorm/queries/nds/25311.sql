
WITH CustomerAddresses AS (
    SELECT 
        ca_address_sk,
        ca_street_number,
        CONCAT(ca_street_number, ' ', TRIM(ca_street_name), ' ', TRIM(ca_street_type), 
               CASE 
                   WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', TRIM(ca_suite_number)) 
                   ELSE '' 
               END) AS full_address,
        ca_city,
        ca_state
    FROM 
        customer_address
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        CASE 
            WHEN LOWER(cd_gender) = 'm' THEN 'Male' 
            WHEN LOWER(cd_gender) = 'f' THEN 'Female' 
            ELSE 'Other' 
        END AS gender_description
    FROM 
        customer_demographics
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
FinalData AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        ca.full_address,
        cd.gender_description,
        sd.total_quantity,
        sd.total_sales,
        sd.total_profit
    FROM 
        customer c
    LEFT JOIN 
        CustomerAddresses ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        SalesData sd ON c.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT 
    customer_name,
    full_address,
    gender_description,
    COALESCE(total_quantity, 0) AS total_quantity,
    COALESCE(total_sales, 0.00) AS total_sales,
    COALESCE(total_profit, 0.00) AS total_profit
FROM 
    FinalData
WHERE 
    gender_description = 'Female' 
    AND total_profit > 1000
ORDER BY 
    total_profit DESC
LIMIT 100;
