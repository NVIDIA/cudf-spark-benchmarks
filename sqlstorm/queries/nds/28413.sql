
WITH AddressStats AS (
    SELECT 
        ca_state,
        COUNT(*) AS address_count,
        MAX(LENGTH(ca_street_name)) AS max_street_name_length,
        MIN(LENGTH(ca_street_name)) AS min_street_name_length,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
DemoStats AS (
    SELECT 
        cd_gender,
        COUNT(*) AS demographic_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        AVG(cd_dep_count) AS avg_dependency_count
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
DateSales AS (
    SELECT 
        d_year,
        SUM(COALESCE(ws_ext_sales_price, 0) + COALESCE(cs_ext_sales_price, 0) + COALESCE(ss_ext_sales_price, 0)) AS total_sales,
        SUM(COALESCE(ws_net_profit, 0) + COALESCE(cs_net_profit, 0) + COALESCE(ss_net_profit, 0)) AS total_profit
    FROM 
        date_dim
    LEFT JOIN 
        web_sales ON d_date_sk = ws_sold_date_sk
    LEFT JOIN 
        catalog_sales ON d_date_sk = cs_sold_date_sk
    LEFT JOIN 
        store_sales ON d_date_sk = ss_sold_date_sk
    GROUP BY 
        d_year
)
SELECT 
    ds.d_year,
    ds.total_sales,
    ds.total_profit,
    as1.address_count,
    as1.max_street_name_length,
    as1.min_street_name_length,
    as1.avg_street_name_length,
    ds1.demographic_count,
    ds1.avg_purchase_estimate,
    ds1.avg_dependency_count
FROM 
    DateSales ds
JOIN 
    AddressStats as1 ON ds.d_year = (SELECT MAX(d_year) FROM date_dim)
JOIN 
    DemoStats ds1 ON ds1.cd_gender = 'F'
ORDER BY 
    ds.d_year DESC;
