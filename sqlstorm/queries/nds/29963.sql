
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS Full_Address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
DemographicsDetails AS (
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
CustomerFullDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ad.Full_Address,
        ad.ca_city,
        ad.ca_state,
        dem.cd_gender,
        dem.cd_marital_status,
        dem.cd_education_status
    FROM 
        customer c
    JOIN 
        AddressDetails ad ON c.c_current_addr_sk = ad.ca_address_sk
    JOIN 
        DemographicsDetails dem ON c.c_current_cdemo_sk = dem.cd_demo_sk
)
SELECT 
    COUNT(*) AS Total_Customers,
    MIN(c_first_name) AS First_Name_Min,
    MAX(c_last_name) AS Last_Name_Max,
    SUM(CASE WHEN cd_gender = 'M' THEN 1 ELSE 0 END) AS Male_Count,
    SUM(CASE WHEN cd_gender = 'F' THEN 1 ELSE 0 END) AS Female_Count,
    ca_state,
    ca_city
FROM 
    CustomerFullDetails
GROUP BY 
    ca_state, ca_city
ORDER BY 
    Total_Customers DESC
LIMIT 10;
