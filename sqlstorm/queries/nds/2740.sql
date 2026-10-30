WITH SalesSummary AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_quantity) DESC) AS sales_rank
    FROM web_sales AS ws
    JOIN date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year >= 2000
    GROUP BY ws.ws_item_sk
),

CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        MAX(cd.cd_purchase_estimate) AS max_purchase_estimate,
        COUNT(CASE WHEN cd.cd_gender = 'F' THEN 1 END) AS female_count,
        COUNT(CASE WHEN cd.cd_gender = 'M' THEN 1 END) AS male_count
    FROM customer_demographics AS cd
    GROUP BY cd.cd_demo_sk
)

SELECT 
    c.c_customer_id,
    ca.ca_city,
    ca.ca_state,
    ss.total_quantity,
    ss.total_sales,
    cd.max_purchase_estimate,
    COALESCE(cd.female_count, 0) AS female_customers,
    COALESCE(cd.male_count, 0) AS male_customers
FROM customer AS c
JOIN customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN SalesSummary AS ss ON c.c_customer_sk = ss.ws_item_sk
LEFT JOIN CustomerDemographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE c.c_current_cdemo_sk IS NOT NULL
  AND (cd.max_purchase_estimate IS NULL OR cd.max_purchase_estimate > 1000)
ORDER BY total_sales DESC
LIMIT 50;