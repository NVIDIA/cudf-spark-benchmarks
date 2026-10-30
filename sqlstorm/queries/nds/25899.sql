
WITH AddressStats AS (
    SELECT 
        ca_state,
        COUNT(*) AS address_count,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length,
        MAX(LENGTH(ca_street_name)) AS max_street_name_length,
        MIN(LENGTH(ca_street_name)) AS min_street_name_length
    FROM 
        customer_address
    WHERE 
        ca_city IS NOT NULL
    GROUP BY 
        ca_state
),
DemographicsStats AS (
    SELECT 
        cd_gender,
        COUNT(*) AS demographic_count,
        AVG(cd_dep_count) AS avg_dep_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
SalesStats AS (
    SELECT 
        CAST(d.d_date AS DATE) AS sale_date,
        COUNT(ws_order_number) AS total_sales,
        SUM(ws_net_paid) AS total_revenue
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        CAST(d.d_date AS DATE)
),
CombinedStats AS (
    SELECT 
        a.ca_state,
        a.address_count,
        a.avg_street_name_length,
        a.max_street_name_length,
        a.min_street_name_length,
        d.cd_gender,
        d.demographic_count,
        d.avg_dep_count,
        d.avg_purchase_estimate,
        s.sale_date,
        s.total_sales,
        s.total_revenue
    FROM 
        AddressStats a
    LEFT JOIN 
        DemographicsStats d ON a.address_count > 100
    LEFT JOIN 
        SalesStats s ON (d.demographic_count > 10 AND s.sale_date BETWEEN '2023-01-01' AND '2023-12-31')
)
SELECT 
    ca_state,
    cd_gender,
    SUM(total_sales) AS total_sales_count,
    SUM(total_revenue) AS total_revenue_amount,
    AVG(avg_street_name_length) AS avg_street_name_length,
    MAX(max_street_name_length) AS max_street_length,
    MIN(min_street_name_length) AS min_street_length
FROM 
    CombinedStats
GROUP BY 
    ca_state, cd_gender, avg_street_name_length, max_street_name_length, min_street_name_length
HAVING 
    SUM(total_sales) > 0
ORDER BY 
    total_revenue_amount DESC;
