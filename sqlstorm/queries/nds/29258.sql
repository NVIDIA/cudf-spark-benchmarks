
WITH AddressSummary AS (
    SELECT 
        ca_state,
        COUNT(*) AS total_addresses,
        STRING_AGG(ca_city, ', ') AS cities_list,
        STRING_AGG(DISTINCT CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type), '; ') AS unique_streets
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
DemographicsSummary AS (
    SELECT 
        cd_gender,
        COUNT(*) AS total_customers,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        STRING_AGG(DISTINCT cd_marital_status, ', ') AS marital_status_list
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
SalesSummary AS (
    SELECT 
        d_year,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS unique_orders,
        STRING_AGG(DISTINCT CAST(ws_web_page_sk AS STRING), ', ') AS web_pages
    FROM 
        web_sales
    JOIN 
        date_dim ON d_date_sk = ws_sold_date_sk
    GROUP BY 
        d_year
)
SELECT 
    AddressSummary.ca_state,
    AddressSummary.total_addresses,
    AddressSummary.cities_list,
    AddressSummary.unique_streets,
    DemographicsSummary.cd_gender,
    DemographicsSummary.total_customers,
    DemographicsSummary.avg_purchase_estimate,
    DemographicsSummary.marital_status_list,
    SalesSummary.d_year,
    SalesSummary.total_sales,
    SalesSummary.unique_orders,
    SalesSummary.web_pages
FROM 
    AddressSummary 
CROSS JOIN 
    DemographicsSummary 
CROSS JOIN 
    SalesSummary 
ORDER BY 
    AddressSummary.ca_state, DemographicsSummary.cd_gender, SalesSummary.d_year;
