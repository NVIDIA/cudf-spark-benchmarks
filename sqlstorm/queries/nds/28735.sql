
WITH RankedAddresses AS (
    SELECT 
        ca_address_sk,
        ca_street_name,
        ca_city,
        ca_state,
        RANK() OVER (PARTITION BY ca_state ORDER BY LENGTH(ca_street_name) DESC) AS name_length_rank
    FROM 
        customer_address
),
FilteredAddresses AS (
    SELECT 
        ca_address_sk,
        ca_street_name,
        ca_city,
        ca_state
    FROM 
        RankedAddresses
    WHERE 
        name_length_rank <= 5
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate
    FROM 
        customer_demographics
    WHERE 
        cd_purchase_estimate > 1000
),
CombinedData AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_street_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM 
        FilteredAddresses ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    JOIN 
        CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
FinalResult AS (
    SELECT 
        CONCAT(ca_street_name, ', ', ca_city, ', ', ca_state) AS full_address,
        COUNT(*) AS customers_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        CombinedData
    GROUP BY 
        full_address
    ORDER BY 
        customers_count DESC
    LIMIT 10
)
SELECT * FROM FinalResult;
