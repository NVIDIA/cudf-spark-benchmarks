
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), AddressProcessing AS (
    SELECT 
        full_name,
        ca_city,
        ca_state,
        CASE 
            WHEN LENGTH(ca_city) > 5 THEN SUBSTRING(ca_city, 1, 5) || '...' 
            ELSE ca_city 
        END AS short_city,
        CONCAT('State: ', ca_state) AS state_info
    FROM 
        CustomerDetails
), GenderStats AS (
    SELECT 
        cd_gender,
        COUNT(*) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase
    FROM 
        CustomerDetails
    GROUP BY 
        cd_gender
), FinalResults AS (
    SELECT 
        ap.full_name,
        ap.short_city,
        ap.state_info,
        gs.customer_count,
        gs.avg_purchase,
        gs.cd_gender
    FROM 
        AddressProcessing ap
    JOIN 
        GenderStats gs ON ap.full_name LIKE '%' || CASE WHEN gs.cd_gender = 'M' THEN '% Male%' ELSE '% Female%' END || '%'
)
SELECT 
    COUNT(*) AS total_customers,
    AVG(avg_purchase) AS average_purchase_by_gender,
    MAX(customer_count) AS max_customers_per_gender,
    MIN(customer_count) AS min_customers_per_gender
FROM 
    FinalResults;
