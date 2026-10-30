
WITH  sales_rank AS (
    SELECT 
        ws_bill_customer_sk,
        ws_item_sk,
        ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY ws_quantity DESC) AS rank
    FROM web_sales
),
customer_returns AS (
    SELECT 
        c.c_customer_id,
        COALESCE(SUM(sr.sr_return_quantity), 0) AS total_returns,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM customer c
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_id
),
high_value_customers AS (
    SELECT 
        cr.c_customer_id,
        cr.total_orders,
        cr.total_returns,
        CASE 
            WHEN cr.total_orders = 0 THEN NULL
            ELSE (cr.total_returns / cr.total_orders) END AS return_rate
    FROM customer_returns cr
    WHERE cr.total_orders > 0
),
qualified_customers AS (
    SELECT 
        cdem.cd_gender,
        cdem.cd_marital_status,
        hdem.hd_income_band_sk,
        hdem.hd_buy_potential,
        COALESCE(SUM(hrc.quant), 0) AS total_quantity
    FROM household_demographics hdem
    JOIN customer_demographics cdem ON hdem.hd_demo_sk = cdem.cd_demo_sk
    JOIN (
        SELECT 
            ws_item_sk,
            ws_quantity AS quant
        FROM web_sales 
        WHERE ws_bill_customer_sk IN (SELECT c_customer_sk FROM customer WHERE c_birth_year > 1980)
    ) hrc ON hdem.hd_buy_potential = 'High'
    GROUP BY cdem.cd_gender, cdem.cd_marital_status, hdem.hd_income_band_sk, hdem.hd_buy_potential
)
SELECT 
    q.cd_gender,
    q.cd_marital_status,
    q.hd_income_band_sk,
    q.hd_buy_potential,
    SUM(q.total_quantity) AS total_quantity,
    COUNT(DISTINCT q.cd_marital_status) AS distinct_marital_status_count
FROM qualified_customers q
LEFT JOIN sales_rank sr ON q.total_quantity > 0
WHERE q.hd_income_band_sk IS NOT NULL
GROUP BY q.cd_gender, q.cd_marital_status, q.hd_income_band_sk, q.hd_buy_potential
HAVING SUM(q.total_quantity) > 100
ORDER BY total_quantity DESC
LIMIT 50;
