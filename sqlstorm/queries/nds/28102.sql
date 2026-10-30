
WITH AddressData AS (
    SELECT 
        ca_city,
        ca_state,
        ca_country,
        COUNT(*) AS address_count,
        STRING_AGG(DISTINCT ca_street_name, ', ') AS unique_street_names
    FROM 
        customer_address
    GROUP BY 
        ca_city, ca_state, ca_country
),
CustomerData AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        SUM(cd_purchase_estimate) AS total_purchase_estimate,
        STRING_AGG(DISTINCT cd_education_status, ', ') AS unique_education_statuses
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender, cd_marital_status
),
SalesData AS (
    SELECT 
        d_year,
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        web_sales
    JOIN 
        date_dim ON ws_sold_date_sk = d_date_sk
    GROUP BY 
        d_year
),
AggregateData AS (
    SELECT 
        ad.ca_city,
        ad.ca_state,
        ad.ca_country,
        ad.address_count,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.total_purchase_estimate,
        sd.total_sales
    FROM 
        AddressData ad
    JOIN 
        CustomerData cd ON 1=1 
    JOIN 
        SalesData sd ON 1=1   
)
SELECT 
    ca_city,
    ca_state,
    ca_country,
    address_count,
    cd_gender,
    cd_marital_status,
    total_purchase_estimate,
    total_sales,
    CONCAT(ca_city, ', ', ca_state, ', ', ca_country) AS full_address,
    CASE 
        WHEN total_sales > 1000000 THEN 'High Sales'
        WHEN total_sales > 500000 THEN 'Moderate Sales'
        ELSE 'Low Sales' 
    END AS sales_category
FROM 
    AggregateData
ORDER BY 
    total_purchase_estimate DESC, 
    total_sales DESC
LIMIT 100;
