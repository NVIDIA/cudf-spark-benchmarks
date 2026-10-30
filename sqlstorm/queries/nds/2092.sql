
WITH RankedReturns AS (
    SELECT
        sr_returned_date_sk,
        sr_item_sk,
        sr_customer_sk,
        RANK() OVER (PARTITION BY sr_item_sk ORDER BY sr_returned_date_sk DESC) AS return_rank,
        SUM(sr_return_quantity) OVER (PARTITION BY sr_item_sk) AS total_returned
    FROM store_returns
),
CustomerDetails AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        COALESCE(hd.hd_income_band_sk, -1) AS income_band_sk,
        hd.hd_buy_potential
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
),
SalesData AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_profit) AS total_profit
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
)
SELECT
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    (SELECT COUNT(DISTINCT wr_order_number) FROM web_returns wr WHERE wr_returning_customer_sk = cd.c_customer_sk) AS total_web_returns,
    COALESCE(rd.return_rank, 0) AS last_return_rank,
    sd.total_quantity_sold,
    sd.total_profit,
    CASE
        WHEN sd.total_profit IS NULL THEN 'No Sales'
        WHEN sd.total_profit > 1000 THEN 'High Profit'
        ELSE 'Low Profit'
    END AS profit_category
FROM CustomerDetails cd
LEFT JOIN RankedReturns rd ON cd.c_customer_sk = rd.sr_customer_sk
LEFT JOIN SalesData sd ON rd.sr_item_sk = sd.ws_item_sk
WHERE (cd.cd_gender = 'F' OR cd.cd_gender IS NULL)
  AND (cd.income_band_sk BETWEEN 1 AND 5 OR cd.income_band_sk IS NULL)
ORDER BY cd.c_last_name, cd.c_first_name;
