WITH address_info AS (
    SELECT 
        ca.ca_address_sk, 
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
        UPPER(ca.ca_city) AS city_upper,
        LOWER(ca.ca_zip) AS zip_lower
    FROM customer_address ca
),
demographic_info AS (
    SELECT 
        cd.cd_demo_sk,
        CONCAT(cd.cd_gender, '-', cd.cd_marital_status, '-', cd.cd_education_status) AS demographic_profile,
        REPLACE(cd.cd_credit_rating, ' ', '_') AS credit_rating_modified
    FROM customer_demographics cd
),
sales_info AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        COUNT(DISTINCT ws.ws_order_number) AS unique_orders
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 1 AND 1000  
    GROUP BY ws.ws_item_sk
),
final_benchmark AS (
    SELECT 
        ai.full_address,
        di.demographic_profile,
        si.total_quantity_sold,
        si.unique_orders,
        ROW_NUMBER() OVER (PARTITION BY ai.city_upper ORDER BY si.total_quantity_sold DESC) AS rank
    FROM address_info ai
    JOIN demographic_info di ON ai.ca_address_sk = di.cd_demo_sk  
    JOIN sales_info si ON ai.ca_address_sk = si.ws_item_sk  
)
SELECT 
    full_address,
    demographic_profile,
    total_quantity_sold,
    unique_orders,
    rank
FROM final_benchmark
WHERE rank <= 10
ORDER BY total_quantity_sold DESC;