
WITH  SalesCTE AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rn
    FROM web_sales ws
    GROUP BY ws.ws_sold_date_sk, ws.ws_item_sk
),
AddressCTE AS (
    SELECT
        ca.ca_address_sk,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address
    FROM customer_address ca
),
CustomerDemographics AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        COALESCE(cd.cd_marital_status, 'Unknown') AS marital_status,
        cd.cd_credit_rating,
        CASE
            WHEN cd.cd_purchase_estimate > 5000 THEN 'High'
            WHEN cd.cd_purchase_estimate BETWEEN 1000 AND 5000 THEN 'Medium'
            ELSE 'Low'
        END AS purchase_category
    FROM customer_demographics cd
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    ad.full_address,
    dem.cd_gender,
    dem.marital_status,
    dem.purchase_category,
    s.total_profit
FROM customer c
LEFT JOIN AddressCTE ad ON c.c_current_addr_sk = ad.ca_address_sk
LEFT JOIN CustomerDemographics dem ON c.c_current_cdemo_sk = dem.cd_demo_sk
LEFT JOIN SalesCTE s ON s.ws_item_sk = c.c_customer_sk
WHERE dem.cd_gender = 'F' 
  AND (s.total_profit IS NULL OR s.total_profit > 1000)
  AND c.c_birth_year < 1980
ORDER BY s.total_profit DESC NULLS LAST
LIMIT 100;
