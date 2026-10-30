WITH RankedAddresses AS (
    SELECT 
        ca_address_sk,
        ca_street_name,
        ca_city,
        ROW_NUMBER() OVER (PARTITION BY ca_city ORDER BY LENGTH(ca_street_name) DESC) AS name_rank
    FROM 
        customer_address
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        CONCAT(cd_gender, '-', cd_marital_status, '-', cd_education_status) AS demographics_key,
        COUNT(DISTINCT c_customer_sk) AS customer_count
    FROM 
        customer_demographics
    JOIN 
        customer ON cd_demo_sk = c_current_cdemo_sk
    GROUP BY 
        cd_demo_sk, cd_gender, cd_marital_status, cd_education_status
),
DateMetrics AS (
    SELECT 
        d_year,
        d_quarter_seq,
        COUNT(DISTINCT d_date_id) AS unique_dates,
        AVG(d_dom) AS avg_day_of_month
    FROM 
        date_dim
    GROUP BY 
        d_year, d_quarter_seq
),
WarehouseInfo AS (
    SELECT 
        w_warehouse_sk,
        w_city,
        SUM(w_warehouse_sq_ft) AS total_sq_ft
    FROM 
        warehouse
    GROUP BY 
        w_warehouse_sk, w_city
),
FinalAggregation AS (
    SELECT 
        a.ca_address_sk,
        a.ca_street_name,
        a.ca_city,
        c.demographics_key,
        c.customer_count,
        d.unique_dates,
        d.avg_day_of_month,
        w.total_sq_ft
    FROM 
        RankedAddresses a
    JOIN 
        CustomerDemographics c ON c.customer_count > 50
    JOIN 
        DateMetrics d ON d.d_year = EXTRACT(YEAR FROM cast('2002-10-01' as date)) 
    JOIN 
        WarehouseInfo w ON a.ca_city = w.w_city
    WHERE 
        a.name_rank = 1
)
SELECT 
    ca_address_sk,
    ca_street_name,
    ca_city,
    demographics_key,
    customer_count,
    unique_dates,
    avg_day_of_month,
    total_sq_ft
FROM 
    FinalAggregation
ORDER BY 
    ca_city, customer_count DESC;