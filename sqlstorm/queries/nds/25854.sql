WITH AddressStats AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT ca_address_id) AS unique_addresses,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
DemographicsStats AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT cd_demo_sk) AS demographic_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk, 
        SUM(ws_quantity) AS total_quantity_sold, 
        SUM(ws_net_paid) AS total_revenue
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
FinalStats AS (
    SELECT 
        a.ca_state,
        a.unique_addresses,
        a.avg_street_name_length,
        d.cd_gender,
        d.demographic_count,
        d.avg_purchase_estimate,
        s.total_quantity_sold,
        s.total_revenue
    FROM 
        AddressStats a
    JOIN 
        DemographicsStats d ON a.ca_state IS NOT NULL  
    JOIN 
        SalesData s ON d.demographic_count > 0           
)

SELECT 
    fs.ca_state,
    fs.unique_addresses,
    fs.avg_street_name_length,
    fs.cd_gender,
    fs.demographic_count,
    fs.avg_purchase_estimate,
    fs.total_quantity_sold,
    fs.total_revenue,
    CONCAT('State: ', fs.ca_state, 
           ', Gender: ', fs.cd_gender, 
           ', Avg Street Name Length: ', fs.avg_street_name_length, 
           ', Total Quantity Sold: ', fs.total_quantity_sold, 
           ', Total Revenue: ', fs.total_revenue) AS benchmark_summary
FROM 
    FinalStats fs
ORDER BY 
    total_revenue DESC;