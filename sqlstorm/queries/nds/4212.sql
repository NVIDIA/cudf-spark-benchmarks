WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk, 
        ws.ws_item_sk, 
        ws.ws_sales_price, 
        ws.ws_quantity, 
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rn
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 2459478 AND 2459479  
),
CustomerPrefs AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_purchase_estimate
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender = 'F' AND cd.cd_purchase_estimate > 500 
),
ReturnsData AS (
    SELECT 
        sr_item_sk, 
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amt
    FROM store_returns
    GROUP BY sr_item_sk
),
TopSales AS (
    SELECT
        sd.ws_item_sk,
        SUM(sd.ws_quantity) AS total_quantity,
        SUM(sd.ws_net_profit) AS total_profit
    FROM SalesData sd
    WHERE sd.rn = 1
    GROUP BY sd.ws_item_sk
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    c.cd_gender,
    ts.total_quantity,
    ts.total_profit,
    COALESCE(rd.total_returns, 0) AS total_returns,
    COALESCE(rd.total_return_amt, 0) AS total_return_amt
FROM CustomerPrefs c
LEFT JOIN TopSales ts ON c.c_customer_sk = ts.ws_item_sk
LEFT JOIN ReturnsData rd ON ts.ws_item_sk = rd.sr_item_sk
WHERE total_profit > 1000  
ORDER BY total_profit DESC, c.c_last_name ASC;