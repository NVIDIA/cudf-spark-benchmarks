
WITH  ranked_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM
        customer c
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
customer_incomes AS (
    SELECT
        hd.hd_demo_sk,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM
        household_demographics hd
    LEFT JOIN
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
top_customers_data AS (
    SELECT
        r.customer_sk,
        r.customer_name,
        CASE
            WHEN r.total_net_profit IS NULL THEN 0
            ELSE r.total_net_profit
        END AS net_profit,
        ci.ib_lower_bound,
        ci.ib_upper_bound
    FROM
        (SELECT 
            c_customer_sk AS customer_sk,
            CONCAT(c_first_name, ' ', c_last_name) AS customer_name,
            total_net_profit
         FROM 
            ranked_sales
         WHERE 
            rank = 1) r
    LEFT JOIN
        customer_incomes ci ON r.customer_sk = ci.hd_demo_sk
)
SELECT 
    window_data.customer_name,
    COALESCE(window_data.net_profit, 0) AS net_profit,
    CASE
        WHEN window_data.ib_lower_bound IS NOT NULL AND window_data.ib_upper_bound IS NOT NULL
        THEN CONCAT('Income Band: $', window_data.ib_lower_bound, ' - $', window_data.ib_upper_bound)
        ELSE 'No Income Band'
    END AS income_band
FROM 
    top_customers_data window_data
WHERE
    window_data.net_profit > 1000
UNION ALL
SELECT 
    'Total',
    SUM(net_profit),
    NULL
FROM 
    top_customers_data
WHERE 
    net_profit IS NOT NULL
ORDER BY 
    net_profit DESC;
