
WITH AddressStats AS (
    SELECT 
        ca_state,
        COUNT(*) AS address_count,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length,
        SUM(LENGTH(ca_city)) AS total_city_length
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
CustomerDemographics AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        COUNT(DISTINCT cd_demo_sk) AS demographic_count
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender, cd_marital_status
),
DateAggregation AS (
    SELECT 
        d_year,
        COUNT(d_date_sk) AS total_days,
        SUM(CASE WHEN d_holiday = 'Y' THEN 1 ELSE 0 END) AS total_holidays
    FROM 
        date_dim
    GROUP BY 
        d_year
),
Combined AS (
    SELECT 
        a.ca_state,
        b.cd_gender,
        b.cd_marital_status,
        c.d_year,
        a.address_count,
        b.avg_purchase_estimate,
        c.total_days,
        c.total_holidays,
        a.avg_street_name_length,
        a.total_city_length
    FROM 
        AddressStats a
    JOIN 
        CustomerDemographics b ON a.address_count > 5
    JOIN 
        DateAggregation c ON c.total_days > 300
)
SELECT 
    ca_state,
    cd_gender,
    cd_marital_status,
    COUNT(*) AS combined_record_count,
    AVG(avg_purchase_estimate) AS avg_purchase_per_group,
    SUM(total_city_length) AS total_city_length_per_group
FROM 
    Combined
GROUP BY 
    ca_state, cd_gender, cd_marital_status
ORDER BY 
    combined_record_count DESC, avg_purchase_per_group DESC;
