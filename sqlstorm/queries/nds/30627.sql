
WITH  CustomerReturns AS (
    SELECT sr_customer_sk, SUM(sr_return_quantity) AS total_returns
    FROM store_returns
    GROUP BY sr_customer_sk
    HAVING SUM(sr_return_quantity) > 0
), HighIncomeDemographics AS (
    SELECT hd_demo_sk, hd_income_band_sk, hd_buy_potential
    FROM household_demographics HD
    JOIN income_band IB ON HD.hd_income_band_sk = IB.ib_income_band_sk
    WHERE IB.ib_upper_bound >= 100000
), SalesData AS (
    SELECT 
        ws_bill_customer_sk, 
        SUM(ws_net_profit) AS total_profit,
        COUNT(ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_profit) DESC) AS rank_profit
    FROM web_sales
    GROUP BY ws_bill_customer_sk
), TopCustomers AS (
    SELECT 
        cd.cd_demo_sk, 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        COALESCE(CR.total_returns, 0) AS total_returns, 
        COALESCE(SD.total_profit, 0) AS total_profit,
        SD.order_count
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN CustomerReturns CR ON c.c_customer_sk = CR.sr_customer_sk
    LEFT JOIN SalesData SD ON c.c_customer_sk = SD.ws_bill_customer_sk
    WHERE cd.cd_marital_status = 'M' AND cd.cd_gender = 'F'
), Result AS (
    SELECT 
        TC.c_customer_sk, 
        TC.c_first_name, 
        TC.c_last_name, 
        TC.total_returns,
        TC.total_profit, 
        HIB.hd_buy_potential
    FROM TopCustomers TC
    JOIN HighIncomeDemographics HIB ON TC.cd_demo_sk = HIB.hd_demo_sk
    WHERE TC.total_profit > 5000 AND TC.total_returns > 2
)
SELECT 
    R.c_customer_sk, 
    R.c_first_name, 
    R.c_last_name, 
    R.total_returns, 
    R.total_profit,
    R.hd_buy_potential,
    CASE 
        WHEN R.total_profit > 10000 THEN 'High Value'
        WHEN R.total_profit BETWEEN 5000 AND 10000 THEN 'Medium Value'
        ELSE 'Low Value' 
    END AS customer_value_category
FROM Result R
ORDER BY R.total_profit DESC, R.total_returns DESC
LIMIT 50;
