
WITH ranked_sales AS (
    SELECT 
        ws_ship_mode_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_ship_mode_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM web_sales
    WHERE ws_ship_date_sk BETWEEN 2450000 AND 2450600
    GROUP BY ws_ship_mode_sk
),
filtered_addresses AS (
    SELECT 
        ca_state,
        ca_city,
        COUNT(DISTINCT ca_address_sk) AS unique_address_count
    FROM customer_address
    WHERE ca_country = 'USA' AND ca_state IS NOT NULL
    GROUP BY ca_state, ca_city
),
customer_demographics AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        COUNT(cd_demo_sk) AS demographic_count
    FROM customer_demographics
    GROUP BY cd_gender, cd_marital_status
)
SELECT 
    addr.ca_city,
    addr.ca_state,
    dem.cd_gender,
    dem.cd_marital_status,
    addr.unique_address_count,
    sales.total_quantity,
    sales.total_net_profit,
    sales.rank
FROM ranked_sales sales
JOIN filtered_addresses addr ON sales.ws_ship_mode_sk = addr.unique_address_count
LEFT JOIN customer_demographics dem ON sales.ws_ship_mode_sk = dem.demographic_count
WHERE addr.unique_address_count IS NOT NULL
AND (addr.ca_city LIKE 'New%' OR addr.ca_state IN ('CA', 'NY'))
UNION ALL
SELECT 
    'N/A' AS ca_city,
    'N/A' AS ca_state,
    'N/A' AS cd_gender,
    'N/A' AS cd_marital_status,
    0 AS unique_address_count,
    SUM(ws_quantity) AS total_quantity,
    SUM(ws_net_profit) AS total_net_profit,
    NULL AS rank
FROM web_sales
WHERE ws_sold_date_sk IS NULL
GROUP BY ws_ship_mode_sk
HAVING SUM(ws_quantity) > 100
ORDER BY total_net_profit DESC;
