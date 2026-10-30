
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk) AS rank_order,
        SUM(ws_net_paid) OVER (PARTITION BY ws_item_sk) AS total_net_paid
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) - 60 FROM date_dim WHERE d_year = 2023)
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate BETWEEN 100 AND 1000
),
AddressInfo AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_country ORDER BY ca.ca_city) AS city_rank
    FROM 
        customer_address AS ca
    WHERE 
        ca.ca_state IS NOT NULL
),
SalesAggregate AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        web_sales AS ws
    GROUP BY 
        ws.ws_item_sk
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ai.ca_city,
    ai.ca_state,
    ai.ca_country,
    SUM(r.ws_net_profit) AS total_profit,
    COUNT(DISTINCT r.rank_order) AS sales_days,
    MAX(r.total_net_paid) AS highest_net_paid,
    COALESCE(SUM(sa.total_quantity), 0) AS total_web_sales
FROM 
    CustomerInfo AS ci
LEFT JOIN 
    AddressInfo AS ai ON ci.c_customer_sk = ai.ca_address_sk
LEFT JOIN 
    RankedSales AS r ON ci.c_customer_sk = r.ws_item_sk
FULL OUTER JOIN 
    SalesAggregate AS sa ON r.ws_item_sk = sa.ws_item_sk
WHERE 
    ai.city_rank < 10 AND (ci.cd_marital_status = 'S' OR ci.cd_gender IS NULL)
GROUP BY 
    ci.c_first_name, ci.c_last_name, ai.ca_city, ai.ca_state, ai.ca_country
HAVING 
    SUM(r.ws_net_profit) > 0 AND (MAX(r.total_net_paid) IS NOT NULL OR COALESCE(SUM(sa.total_quantity), 0) < 100)
ORDER BY 
    total_profit DESC;
