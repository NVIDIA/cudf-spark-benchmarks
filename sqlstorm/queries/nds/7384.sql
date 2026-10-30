
WITH CustomerDetails AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_profit,
        dd.d_date
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2023
),
ProfitAggregates AS (
    SELECT 
        cd.c_customer_sk,
        SUM(sd.ws_net_profit) AS total_profit,
        COUNT(sd.ws_item_sk) AS total_sales
    FROM CustomerDetails cd
    JOIN SalesData sd ON cd.c_customer_sk = sd.ws_item_sk
    GROUP BY cd.c_customer_sk
)
SELECT 
    cd.c_first_name,
    cd.c_last_name,
    ca.ca_city,
    ca.ca_state,
    pa.total_profit,
    pa.total_sales
FROM CustomerDetails cd
JOIN customer_address ca ON cd.c_customer_sk = ca.ca_address_sk
JOIN ProfitAggregates pa ON cd.c_customer_sk = pa.c_customer_sk
WHERE pa.total_profit > 1000
ORDER BY pa.total_profit DESC
LIMIT 10;
