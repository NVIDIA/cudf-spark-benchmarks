
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city AS city,
        ca.ca_state AS state,
        ca.ca_zip,
        ca.ca_country,
        COALESCE(hd.hd_buy_potential, 'Unknown') AS buy_potential,
        hd.hd_dep_count,
        hd.hd_vehicle_count,
        CASE 
            WHEN cd.cd_purchase_estimate IS NULL THEN 'Not Available'
            ELSE 
                CASE 
                    WHEN cd.cd_purchase_estimate < 1000 THEN 'Low'
                    WHEN cd.cd_purchase_estimate <= 5000 THEN 'Medium'
                    ELSE 'High'
                END 
        END AS purchase_estimate_category
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
), 
AggregatedResults AS (
    SELECT 
        city,
        state,
        COUNT(DISTINCT c_customer_id) AS unique_customers,
        AVG(hd_dep_count) AS average_dependents,
        AVG(hd_vehicle_count) AS average_vehicles,
        COUNT(CASE WHEN purchase_estimate_category = 'High' THEN 1 END) AS high_estimate_count
    FROM 
        CustomerDetails
    GROUP BY 
        city, 
        state
)
SELECT 
    city,
    state,
    unique_customers,
    average_dependents,
    average_vehicles,
    high_estimate_count,
    CONCAT('Area: ', city, ', ', state) AS area_description,
    'Total Customers: ' || unique_customers || ', Avg Dependents: ' || average_dependents || ', Avg Vehicles: ' || average_vehicles || ', High Purchase Estimates: ' || high_estimate_count AS summary
FROM 
    AggregatedResults
ORDER BY 
    unique_customers DESC;
