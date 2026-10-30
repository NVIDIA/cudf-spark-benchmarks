
WITH customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        iw.income_band,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rn
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN (
        SELECT 
            h.hd_demo_sk, 
            CASE 
                WHEN ib.ib_income_band_sk IS NOT NULL THEN CONCAT('Income Band: ', ib.ib_lower_bound, ' - ', ib.ib_upper_bound) 
                ELSE 'No Income Band' 
            END AS income_band
        FROM household_demographics h
        LEFT JOIN income_band ib ON h.hd_income_band_sk = ib.ib_income_band_sk
    ) iw ON iw.hd_demo_sk = cd.cd_demo_sk
    WHERE cd.cd_purchase_estimate > (SELECT AVG(cd_purchase_estimate) FROM customer_demographics)
),
active_sales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2023 AND d.d_month_seq BETWEEN 1 AND 6
    GROUP BY ws.ws_item_sk
    HAVING SUM(ws.ws_quantity) > 0
),
high_return_items AS (
    SELECT 
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_returns,
        COUNT(DISTINCT cr.cr_order_number) AS return_count
    FROM catalog_returns cr
    GROUP BY cr.cr_item_sk
    HAVING SUM(cr.cr_return_quantity) > (SELECT AVG(cr_return_quantity) FROM catalog_returns)
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cs.cd_gender,
    cs.cd_marital_status,
    COALESCE(a.total_quantity, 0) AS total_sales_quantity,
    COALESCE(a.total_profit, 0) AS total_sales_profit,
    COALESCE(r.total_returns, 0) AS total_returns,
    CASE 
        WHEN COALESCE(a.total_profit, 0) > 0 THEN 'Profitable'
        WHEN COALESCE(r.total_returns, 0) > 0 THEN 'Returns'
        ELSE 'Neutral'
    END AS financial_status
FROM customer_summary cs
LEFT JOIN active_sales a ON a.ws_item_sk = cs.c_customer_sk
LEFT JOIN high_return_items r ON r.cr_item_sk = a.ws_item_sk
WHERE cs.rn <= 5 AND (a.total_quantity IS NOT NULL OR r.total_returns IS NOT NULL)
ORDER BY financial_status DESC, cs.c_last_name, cs.c_first_name;
