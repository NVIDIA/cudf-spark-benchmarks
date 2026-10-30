
WITH  address_data AS (
    SELECT ca_address_sk, ca_city, 
           CASE 
               WHEN ca_zip IS NULL THEN 'Unknown'
               ELSE ca_zip 
           END AS zip_code
    FROM customer_address
    UNION ALL
    SELECT ca_address_sk, ca_city, 
           CONCAT('City: ', ca_city)
    FROM customer_address
    WHERE ca_city IS NOT NULL
), sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM web_sales
    GROUP BY ws_item_sk
), demographics_summary AS (
    SELECT 
        cd_gender,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        COUNT(*) AS demographic_count
    FROM customer_demographics
    WHERE cd_marital_status IN ('M', 'S')
    GROUP BY cd_gender
)
SELECT 
    a.ca_city, 
    a.zip_code, 
    dem.cd_gender,
    dem.avg_purchase_estimate,
    s.total_quantity,
    s.total_profit,
    (SELECT COUNT(*) FROM store_sales ss WHERE ss.ss_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)) AS total_sales,
    CASE 
        WHEN s.total_profit IS NULL THEN 'No Profit Data'
        ELSE CAST(s.total_profit AS VARCHAR(20))
    END AS profit_message,
    EXISTS (
        SELECT 1
        FROM customer c
        WHERE c.c_birth_month = 12 
          AND c.c_birth_day IS NOT NULL 
          AND c.c_birth_year IS NOT NULL
    ) AS december_birth_existence,
    ROW_NUMBER() OVER(PARTITION BY a.ca_city ORDER BY s.total_profit DESC) AS city_profit_rank
FROM address_data a
FULL OUTER JOIN sales_summary s ON a.ca_address_sk = s.ws_item_sk
LEFT JOIN demographics_summary dem ON dem.cd_gender = (SELECT DISTINCT cd_gender FROM customer_demographics LIMIT 1)
WHERE a.zip_code IS NOT NULL 
  AND (dem.avg_purchase_estimate > 100 OR dem.demographic_count < 5)
GROUP BY a.ca_city, a.zip_code, dem.cd_gender, dem.avg_purchase_estimate, s.total_quantity, s.total_profit
ORDER BY a.ca_city, s.total_profit DESC;
