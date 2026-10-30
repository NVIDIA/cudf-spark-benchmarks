
WITH  income_bucket AS (
    SELECT ib_income_band_sk, ib_lower_bound, ib_upper_bound
    FROM income_band
    WHERE ib_lower_bound IS NOT NULL
), customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT CASE WHEN ws.ws_sold_date_sk IS NOT NULL THEN ws.ws_order_number END) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit,
        SUM(CASE WHEN ws.ws_net_profit IS NULL THEN 0 ELSE ws.ws_net_profit END) AS adjusted_profit,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_customer_id, cd.cd_gender, cd.cd_marital_status
)
SELECT 
    ci.c_customer_id,
    ci.cd_gender,
    ci.cd_marital_status,
    COALESCE(b.ib_income_band_sk, -1) AS income_band,
    ci.total_orders,
    ci.total_profit,
    ci.adjusted_profit
FROM customer_info ci
LEFT JOIN (
    SELECT 
        hd.hd_demo_sk,
        hb.ib_income_band_sk
    FROM household_demographics hd
    JOIN income_bucket hb ON hd.hd_income_band_sk = hb.ib_income_band_sk
    WHERE hb.ib_upper_bound > 
        (SELECT AVG(total_profit) FROM customer_info)
) b ON ci.c_customer_sk = b.hd_demo_sk
WHERE ci.profit_rank <= 10
  AND (ci.cd_marital_status IS NOT NULL OR ci.cd_marital_status IS NULL)
ORDER BY ci.total_profit DESC
LIMIT 100 OFFSET 0;
