
WITH  SalesCTE AS (
    SELECT
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM web_sales
    GROUP BY ws_sold_date_sk, ws_item_sk
),
CustomerInfo AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ua.ca_city,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY c.c_birth_year DESC) AS rn
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN customer_address ua ON c.c_current_addr_sk = ua.ca_address_sk
),
ProfitRanking AS (
    SELECT
        si.ws_item_sk,
        si.total_quantity,
        si.total_profit,
        ra.ca_city,
        ROW_NUMBER() OVER (PARTITION BY ra.ca_city ORDER BY si.total_profit DESC) AS city_rank
    FROM SalesCTE si
    JOIN warehouse w ON si.ws_item_sk = w.w_warehouse_sk
    JOIN customer_address ra ON w.w_warehouse_sk = ra.ca_address_sk
)
SELECT
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    case when ci.cd_marital_status = 'M' then 'Married' else 'Single' end AS marital_status,
    pr.ws_item_sk,
    pr.total_quantity,
    pr.total_profit
FROM CustomerInfo ci
JOIN ProfitRanking pr ON ci.c_customer_sk = pr.ws_item_sk
WHERE pr.city_rank <= 5
    AND ci.rn = 1
    AND pr.total_profit IS NOT NULL
    AND pr.total_quantity > 100
ORDER BY pr.total_profit DESC;
