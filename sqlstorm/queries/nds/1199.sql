
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2023
    GROUP BY ws.ws_item_sk
),
CustomerData AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(cd.cd_gender, 'U') AS gender,
        COALESCE(hd.hd_income_band_sk, ib.ib_income_band_sk) AS income_band
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
RankedReturns AS (
    SELECT 
        sr.sr_customer_sk,
        COUNT(*) AS total_returns,
        SUM(sr.sr_return_amt) AS total_return_amt,
        RANK() OVER (PARTITION BY sr.sr_customer_sk ORDER BY COUNT(*) DESC) AS return_rank
    FROM store_returns sr
    GROUP BY sr.sr_customer_sk
    HAVING COUNT(*) > 1
)
SELECT 
    cd.gender,
    cd.income_band,
    COALESCE(sd.total_quantity, 0) AS total_quantity,
    COALESCE(sd.total_net_profit, 0) AS total_net_profit,
    rr.total_returns,
    rr.total_return_amt
FROM CustomerData cd
LEFT JOIN SalesData sd ON cd.c_customer_sk = (SELECT ws.ws_bill_customer_sk FROM web_sales ws WHERE ws.ws_item_sk IN (SELECT ws_item_sk FROM SalesData WHERE profit_rank = 1) LIMIT 1)
LEFT JOIN RankedReturns rr ON cd.c_customer_sk = rr.sr_customer_sk
WHERE (cd.gender = 'M' OR cd.gender = 'F') AND cd.income_band IS NOT NULL
ORDER BY cd.gender, total_net_profit DESC;
