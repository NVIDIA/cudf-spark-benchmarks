WITH AddressAnalysis AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country,
        LENGTH(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS address_length,
        CASE 
            WHEN LENGTH(ca_street_name) > 30 THEN 'long' 
            ELSE 'short' 
        END AS street_name_length_category
    FROM 
        customer_address
),
GenderDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        COUNT(*) AS customer_count,
        AVG(cd_dep_count) AS avg_dependency_count
    FROM 
        customer_demographics
    GROUP BY 
        cd_demo_sk, cd_gender
),
DateMetrics AS (
    SELECT 
        d_year,
        d_month_seq,
        COUNT(*) AS total_sales_days,
        SUM(CASE WHEN d_holiday = 'Y' THEN 1 ELSE 0 END) AS holiday_sales_days
    FROM 
        date_dim
    GROUP BY 
        d_year, d_month_seq
),
FinalReport AS (
    SELECT 
        aa.full_address,
        aa.ca_city,
        aa.ca_state,
        aa.ca_zip,
        aa.ca_country,
        gd.cd_gender,
        gd.customer_count,
        gd.avg_dependency_count,
        dm.d_year,
        dm.d_month_seq,
        dm.total_sales_days,
        dm.holiday_sales_days
    FROM 
        AddressAnalysis aa
    JOIN 
        customer c ON c.c_current_addr_sk = aa.ca_address_sk
    JOIN 
        GenderDemographics gd ON gd.cd_demo_sk = c.c_current_cdemo_sk
    JOIN 
        DateMetrics dm ON dm.d_year = EXTRACT(YEAR FROM cast('2002-10-01' as date))
    WHERE 
        aa.street_name_length_category = 'long'
)
SELECT 
    full_address,
    ca_city,
    ca_state,
    ca_zip,
    ca_country,
    cd_gender,
    customer_count,
    avg_dependency_count,
    d_year,
    d_month_seq,
    total_sales_days,
    holiday_sales_days
FROM 
    FinalReport
ORDER BY 
    ca_city, ca_state, customer_count DESC;