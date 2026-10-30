
WITH AddressCounts AS (
    SELECT 
        ca_state, 
        COUNT(*) AS address_count,
        SUM(LENGTH(ca_street_name)) AS total_street_name_length,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
CustomerDemographics AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        COUNT(*) AS demographic_count,
        MAX(cd_purchase_estimate) AS max_purchase_estimate,
        MIN(cd_purchase_estimate) AS min_purchase_estimate
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender, 
        cd_marital_status
),
SalesAggregate AS (
    SELECT 
        ws_sold_date_sk,
        SUM(ws_quantity) AS total_sold_quantity,
        SUM(ws_net_paid) AS total_sales_value
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk
),
FinalResult AS (
    SELECT 
        ac.ca_state,
        ac.address_count,
        ac.total_street_name_length,
        ac.avg_street_name_length,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.demographic_count,
        cd.max_purchase_estimate,
        cd.min_purchase_estimate,
        sa.total_sold_quantity,
        sa.total_sales_value
    FROM 
        AddressCounts ac
    JOIN 
        CustomerDemographics cd ON cd.demographic_count > 100
    JOIN 
        SalesAggregate sa ON ac.address_count > 500
)
SELECT 
    ca_state,
    address_count,
    total_street_name_length,
    avg_street_name_length,
    cd_gender,
    cd_marital_status,
    demographic_count,
    max_purchase_estimate,
    min_purchase_estimate,
    total_sold_quantity,
    total_sales_value
FROM 
    FinalResult
ORDER BY 
    total_sales_value DESC, 
    address_count DESC;
