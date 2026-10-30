WITH AddressSummary AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT ca_address_sk) AS unique_addresses,
        COUNT(DISTINCT ca_city) AS unique_cities,
        SUM(LENGTH(TRIM(ca_street_name))) AS total_street_name_length,
        AVG(LENGTH(TRIM(ca_street_name))) AS avg_street_name_length
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
CustomerDemographics AS (
    SELECT 
        cd_gender,
        COUNT(c_customer_sk) AS customer_count,
        AVG(cd_dep_count) AS avg_dependents,
        SUM(cd_purchase_estimate) AS total_purchase_estimate
    FROM 
        customer
    INNER JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY 
        cd_gender
),
ReturnAnalysis AS (
    SELECT 
        sr_store_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount,
        COUNT(DISTINCT sr_ticket_number) AS unique_return_tickets
    FROM 
        store_returns
    GROUP BY 
        sr_store_sk
)
SELECT 
    a.ca_state,
    a.unique_addresses,
    a.unique_cities,
    a.total_street_name_length,
    a.avg_street_name_length,
    cd.cd_gender,
    cd.customer_count,
    cd.avg_dependents,
    cd.total_purchase_estimate,
    ra.total_returns,
    ra.total_return_amount,
    ra.unique_return_tickets
FROM 
    AddressSummary a
JOIN 
    CustomerDemographics cd ON 1=1  
JOIN 
    ReturnAnalysis ra ON ra.total_returns > 0  
ORDER BY 
    a.unique_addresses DESC, 
    cd.customer_count DESC;