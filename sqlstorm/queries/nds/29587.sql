WITH AddressAnalytics AS (
    SELECT 
        ca_address_sk,
        UPPER(ca_city) AS city_upper,
        LENGTH(ca_street_name) AS street_name_length,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        REGEXP_REPLACE(ca_zip, '[^0-9]', '') AS cleaned_zip
    FROM 
        customer_address
), GenderDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        COUNT(*) AS gender_count
    FROM 
        customer_demographics
    GROUP BY 
        cd_demo_sk, cd_gender
), DateSummary AS (
    SELECT 
        d_year,
        COUNT(*) AS total_days,
        MAX(d_date) AS last_date,
        MIN(d_date) AS first_date
    FROM 
        date_dim
    GROUP BY 
        d_year
)
SELECT 
    aa.ca_address_sk,
    aa.city_upper,
    aa.street_name_length,
    aa.full_address,
    aa.cleaned_zip,
    gd.cd_gender,
    gd.gender_count,
    ds.d_year,
    ds.total_days,
    ds.first_date,
    ds.last_date
FROM 
    AddressAnalytics aa
JOIN 
    customer c ON c.c_current_addr_sk = aa.ca_address_sk
JOIN 
    GenderDemographics gd ON c.c_current_cdemo_sk = gd.cd_demo_sk
JOIN 
    DateSummary ds ON EXTRACT(YEAR FROM cast('2002-10-01' as date)) = ds.d_year
WHERE 
    aa.street_name_length > 10
ORDER BY 
    aa.city_upper, gd.gender_count DESC;