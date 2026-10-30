
WITH AddressStats AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT ca_address_sk) AS address_count,
        MAX(LENGTH(ca_street_name)) AS max_street_name_length,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
CustomerDemographics AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT cd_demo_sk) AS demographic_count,
        AVG(cd_dep_count) AS avg_dependents,
        MAX(cd_purchase_estimate) AS max_purchase_estimate
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
DateInfo AS (
    SELECT 
        d_year,
        COUNT(DISTINCT d_date_sk) AS total_days,
        MAX(DATE_PART('dow', d_date)) AS max_day_of_week,
        AVG(EXTRACT(DAY FROM d_date)) AS avg_day_of_month
    FROM 
        date_dim
    GROUP BY 
        d_year
)
SELECT 
    ds.ca_state,
    ds.address_count,
    ds.max_street_name_length,
    ds.avg_street_name_length,
    cd.cd_gender,
    cd.demographic_count,
    cd.avg_dependents,
    cd.max_purchase_estimate,
    di.d_year,
    di.total_days,
    di.max_day_of_week,
    di.avg_day_of_month
FROM 
    AddressStats ds
JOIN 
    CustomerDemographics cd ON ds.address_count > 10
JOIN 
    DateInfo di ON di.total_days > 200
ORDER BY 
    ds.ca_state, cd.cd_gender, di.d_year;
