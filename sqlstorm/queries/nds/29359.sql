
WITH AddressCount AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT ca_address_id) AS unique_addresses,
        STRING_AGG(DISTINCT ca_city, ', ') AS cities
    FROM 
        customer_address
    GROUP BY 
        ca_state
), DemographicsSummary AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c_customer_id) AS customer_count,
        AVG(cd_dep_count) AS avg_dependents,
        STRING_AGG(DISTINCT cd_credit_rating, ', ') AS credit_ratings
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd_gender
), SalesSummary AS (
    SELECT 
        i_category,
        SUM(ws_quantity) AS total_quantity_sold,
        AVG(ws_sales_price) AS avg_sales_price,
        STRING_AGG(DISTINCT CAST(ws_web_site_sk AS STRING), ', ') AS selling_websites
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY 
        i_category
)
SELECT 
    ac.ca_state,
    ac.unique_addresses,
    ac.cities,
    ds.cd_gender,
    ds.customer_count,
    ds.avg_dependents,
    ds.credit_ratings,
    ss.i_category,
    ss.total_quantity_sold,
    ss.avg_sales_price,
    ss.selling_websites
FROM 
    AddressCount ac
JOIN 
    DemographicsSummary ds ON ac.ca_state = 'CA'  
JOIN 
    SalesSummary ss ON ss.total_quantity_sold > 1000  
ORDER BY 
    ac.ca_state, ds.cd_gender, ss.total_quantity_sold DESC;
