
WITH customer_info AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        ca.ca_city,
        ca.ca_state,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status, 
        hd.hd_income_band_sk, 
        hd.hd_buy_potential, 
        ca.ca_city, 
        ca.ca_state
),
income_distribution AS (
    SELECT 
        hd.hd_income_band_sk,
        COUNT(*) AS customer_count,
        AVG(ci.total_net_profit) AS avg_net_profit
    FROM customer_info ci
    JOIN household_demographics hd ON ci.hd_income_band_sk = hd.hd_income_band_sk
    GROUP BY hd.hd_income_band_sk
)
SELECT 
    id.hd_income_band_sk,
    id.customer_count,
    id.avg_net_profit,
    CASE
        WHEN id.avg_net_profit < 500 THEN 'Low'
        WHEN id.avg_net_profit BETWEEN 500 AND 1500 THEN 'Medium'
        ELSE 'High'
    END AS income_category
FROM income_distribution id
ORDER BY id.avg_net_profit DESC
LIMIT 10;
