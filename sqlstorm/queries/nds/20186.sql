
WITH  CustomerCTE AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        COALESCE(cd.cd_gender, 'U') AS gender, 
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COALESCE(ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC), 0) AS gender_rank
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), SalesCTE AS (
    SELECT 
        ws.ws_sold_date_sk, 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS item_rank
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY ws.ws_sold_date_sk, ws.ws_item_sk
), ReturnAnalysis AS (
    SELECT 
        SUM(cr.cr_return_quantity) AS total_returns,
        cr.cr_item_sk,
        SUM(cr.cr_return_amount) AS total_return_amount
    FROM catalog_returns cr
    WHERE cr.cr_returned_date_sk > 0
    GROUP BY cr.cr_item_sk
), IncomeBandCTE AS (
    SELECT 
        hd.hd_demo_sk,
        ib.ib_income_band_sk,
        COUNT(hd.hd_demo_sk) as income_band_count
    FROM household_demographics hd
    LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY hd.hd_demo_sk, ib.ib_income_band_sk
)
SELECT 
    cte.c_customer_sk,
    cte.c_first_name || ' ' || cte.c_last_name AS full_name,
    COALESCE(s.total_quantity, 0) AS total_sales_quantity,
    COALESCE(s.total_profit, 0) AS total_sales_profit,
    ra.total_returns AS returns_quantity,
    ra.total_return_amount,
    ibc.income_band_count
FROM CustomerCTE cte
LEFT JOIN SalesCTE s ON cte.c_customer_sk = s.ws_item_sk
LEFT JOIN ReturnAnalysis ra ON ra.cr_item_sk = s.ws_item_sk
LEFT JOIN IncomeBandCTE ibc ON cte.c_customer_sk = ibc.hd_demo_sk
WHERE 
    (cte.gender = 'F' AND cte.cd_purchase_estimate < 5000) OR 
    (cte.gender = 'M' AND cte.cd_marital_status = 'S' AND cte.cd_purchase_estimate > (SELECT AVG(cd_purchase_estimate) FROM customer_demographics))
ORDER BY 
    COALESCE(s.total_profit, 0) DESC, 
    cte.gender_rank NULLS LAST
LIMIT 50;
