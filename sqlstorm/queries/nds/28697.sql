
WITH Address_Statistics AS (
    SELECT 
        ca_city,
        ca_state,
        COUNT(DISTINCT ca_address_id) AS unique_addresses,
        COUNT(DISTINCT ca_street_name) AS unique_streets,
        SUM(LENGTH(ca_street_name)) AS total_street_length
    FROM 
        customer_address
    GROUP BY 
        ca_city,
        ca_state
),
Demographics_Statistics AS (
    SELECT 
        cd_gender,
        COUNT(*) AS customers,
        AVG(cd_purchase_estimate) AS average_purchase_estimate
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
Sales_Statistics AS (
    SELECT 
        ws_bill_cdemo_sk AS demographic_sk,
        SUM(ws_net_paid) AS total_sales,
        SUM(ws_quantity) AS total_quantity
    FROM 
        web_sales
    WHERE 
        ws_bill_cdemo_sk IS NOT NULL
    GROUP BY 
        ws_bill_cdemo_sk
),
Final_Statistics AS (
    SELECT 
        a.ca_city,
        a.ca_state,
        d.cd_gender,
        d.customers,
        d.average_purchase_estimate,
        s.total_sales,
        s.total_quantity
    FROM 
        Address_Statistics a
    JOIN 
        Demographics_Statistics d ON a.ca_city = d.cd_gender
    LEFT JOIN 
        Sales_Statistics s ON d.customers = s.demographic_sk
)
SELECT 
    ca_city,
    ca_state,
    cd_gender,
    customers,
    average_purchase_estimate,
    COALESCE(total_sales, 0) AS total_sales,
    COALESCE(total_quantity, 0) AS total_quantity
FROM 
    Final_Statistics
ORDER BY 
    ca_state, 
    ca_city;
