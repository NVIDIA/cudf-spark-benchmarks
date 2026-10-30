
WITH RankedAddresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS Full_Street_Name,
        ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY ca_city) AS State_Rank
    FROM 
        customer_address
    WHERE 
        ca_city IS NOT NULL
),
FilteredDemographics AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        cd_education_status,
        COUNT(DISTINCT c_customer_sk) AS Customer_Count
    FROM 
        customer_demographics
    JOIN customer ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY 
        cd_gender, 
        cd_marital_status, 
        cd_education_status
),
CustomerAddressSummary AS (
    SELECT 
        a.Full_Street_Name, 
        d.cd_gender, 
        d.cd_marital_status, 
        d.cd_education_status, 
        d.Customer_Count
    FROM 
        RankedAddresses a
    JOIN FilteredDemographics d ON d.Customer_Count > 0
)
SELECT 
    Full_Street_Name, 
    cd_gender, 
    cd_marital_status, 
    cd_education_status, 
    Customer_Count, 
    SUM(Customer_Count) OVER (PARTITION BY cd_gender ORDER BY Full_Street_Name) AS Cumulative_Count
FROM 
    CustomerAddressSummary
WHERE 
    cd_gender IS NOT NULL
ORDER BY 
    Full_Street_Name, 
    cd_gender;
