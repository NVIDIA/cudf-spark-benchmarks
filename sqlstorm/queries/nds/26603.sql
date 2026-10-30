
WITH city_counts AS (
    SELECT 
        ca_city,
        COUNT(DISTINCT c_customer_sk) AS num_customers
    FROM 
        customer_address
    JOIN 
        customer ON ca_address_sk = c_current_addr_sk
    GROUP BY 
        ca_city
), 
formatted_city_info AS (
    SELECT 
        ca_city,
        CONCAT(ca_city, ' - Count: ', num_customers) AS city_info,
        num_customers
    FROM 
        city_counts
    WHERE 
        num_customers > 10
), 
ranked_cities AS (
    SELECT 
        city_info,
        DENSE_RANK() OVER (ORDER BY num_customers DESC) AS city_rank
    FROM 
        formatted_city_info
)
SELECT 
    city_info
FROM 
    ranked_cities
WHERE 
    city_rank <= 5
ORDER BY 
    city_rank;
