
WITH formatted_addresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               COALESCE(CONCAT(' Suite ', ca_suite_number), ''), 
               ', ', ca_city, ', ', ca_state, ' ', ca_zip, 
               ' - ', ca_country) AS full_address
    FROM 
        customer_address
),
gender_statistics AS (
    SELECT 
        cd_gender,
        COUNT(*) AS customer_count,
        AVG(cd_dep_count) AS avg_dependency_count,
        cd_demo_sk
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender, cd_demo_sk
),
sales_summary AS (
    SELECT
        CASE 
            WHEN ws_sales_price < 100 THEN 'Low'
            WHEN ws_sales_price BETWEEN 100 AND 500 THEN 'Medium'
            ELSE 'High'
        END AS price_range,
        SUM(ws_net_profit) AS total_net_profit
    FROM 
        web_sales
    GROUP BY 
        price_range
)
SELECT 
    f.ca_address_sk,
    f.full_address,
    g.cd_gender,
    g.customer_count,
    g.avg_dependency_count,
    s.price_range,
    s.total_net_profit
FROM 
    formatted_addresses f
JOIN 
    customer c ON f.ca_address_sk = c.c_current_addr_sk
JOIN 
    gender_statistics g ON c.c_current_cdemo_sk = g.cd_demo_sk
JOIN 
    sales_summary s ON s.price_range IN ('Low', 'Medium', 'High')
ORDER BY 
    f.ca_address_sk, g.cd_gender;
