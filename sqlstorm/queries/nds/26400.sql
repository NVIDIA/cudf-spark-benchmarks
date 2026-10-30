
WITH CustomerAddressDetails AS (
    SELECT 
        ca_address_sk,
        ca_street_name,
        ca_city,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        LENGTH(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS address_length
    FROM 
        customer_address
),
DemographicInsights AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        SUBSTRING(cd_education_status, 1, 3) AS education_abbreviation,
        cd_purchase_estimate
    FROM 
        customer_demographics
),
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
FinalAnalysis AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cad.full_address, 
        di.education_abbreviation, 
        si.total_profit
    FROM 
        customer c
    JOIN 
        CustomerAddressDetails cad ON c.c_current_addr_sk = cad.ca_address_sk
    JOIN 
        DemographicInsights di ON c.c_current_cdemo_sk = di.cd_demo_sk
    LEFT JOIN 
        SalesSummary si ON c.c_customer_sk = si.ws_bill_customer_sk
)
SELECT 
    f.c_customer_sk,
    f.c_first_name, 
    f.c_last_name, 
    f.full_address, 
    f.education_abbreviation, 
    f.total_profit,
    CASE 
        WHEN f.total_profit IS NULL THEN 'No Sales'
        WHEN f.total_profit < 0 THEN 'Loss'
        ELSE 'Profit'
    END AS profit_status,
    CONCAT(f.c_first_name, ' ', f.c_last_name) AS full_name,
    SUBSTRING(f.full_address, 1, 60) AS short_address
FROM 
    FinalAnalysis f
WHERE 
    LENGTH(f.full_address) > 25
ORDER BY 
    f.total_profit DESC NULLS LAST, 
    f.c_last_name;
