
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        h.hd_income_band_sk,
        h.hd_buy_potential
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics h ON h.hd_demo_sk = c.c_current_hdemo_sk
),
SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit
    FROM web_sales ws
    GROUP BY ws.ws_sold_date_sk, ws.ws_item_sk
),
DailySales AS (
    SELECT 
        dd.d_date_sk,
        dd.d_date,
        COALESCE(SUM(sd.total_quantity), 0) AS daily_quantity,
        COALESCE(SUM(sd.total_profit), 0) AS daily_profit
    FROM date_dim dd
    LEFT JOIN SalesData sd ON dd.d_date_sk = sd.ws_sold_date_sk
    GROUP BY dd.d_date_sk, dd.d_date
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    d.d_date,
    ds.daily_quantity,
    ds.daily_profit
FROM CustomerInfo ci
JOIN DailySales ds ON ds.daily_quantity > 0
JOIN date_dim d ON ds.d_date = d.d_date
WHERE 
    ci.hd_income_band_sk IN (SELECT ib_income_band_sk FROM income_band WHERE ib_lower_bound > 50000)
    AND ci.cd_marital_status = 'M'
ORDER BY ds.daily_profit DESC
LIMIT 100;
