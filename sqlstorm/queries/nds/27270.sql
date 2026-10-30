
WITH AddressStats AS (
    SELECT 
        ca_state, 
        COUNT(*) AS address_count,
        MAX(ca_zip) AS max_zip, 
        MIN(ca_zip) AS min_zip,
        AVG(ca_gmt_offset) AS avg_gmt_offset
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
DemographicStats AS (
    SELECT 
        cd_gender, 
        COUNT(*) AS demographic_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        MAX(cd_credit_rating) AS max_credit_rating,
        cd_demo_sk  -- include cd_demo_sk for the JOIN condition
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender, cd_demo_sk
),
SalesStats AS (
    SELECT 
        ws_bill_cdemo_sk AS customer_demo_sk, 
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(*) AS sales_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_cdemo_sk
)
SELECT 
    a.ca_state, 
    a.address_count, 
    a.max_zip, 
    a.min_zip, 
    a.avg_gmt_offset,
    d.cd_gender, 
    d.demographic_count, 
    d.avg_purchase_estimate, 
    d.max_credit_rating,
    s.total_net_profit, 
    s.sales_count 
FROM 
    AddressStats a 
JOIN 
    DemographicStats d ON d.demographic_count > 10 
JOIN 
    SalesStats s ON s.customer_demo_sk = d.cd_demo_sk 
WHERE 
    a.address_count > 5 
ORDER BY 
    a.ca_state, d.cd_gender;
