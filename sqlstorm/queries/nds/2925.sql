
WITH CustomerReturns AS (
    SELECT 
        CAST(COALESCE(sr_customer_sk, wr_returning_customer_sk) AS INT) AS customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS store_return_count,
        COUNT(DISTINCT wr_order_number) AS web_return_count
    FROM store_returns sr
    FULL OUTER JOIN web_returns wr ON sr_item_sk = wr_item_sk
    GROUP BY customer_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_net_profit) AS total_web_profit,
        COUNT(ws_order_number) AS total_web_sales
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_dep_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
HighValueCustomers AS (
    SELECT 
        customer_sk,
        total_web_profit,
        (store_return_count + web_return_count) AS total_returns
    FROM CustomerReturns
    JOIN SalesData USING(customer_sk)
    WHERE total_web_profit > 1000
),
FinalReport AS (
    SELECT 
        cv.customer_sk,
        cv.total_web_profit,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_dep_count,
        CASE 
            WHEN cv.total_returns > 10 THEN 'High Return'
            ELSE 'Normal Return' 
        END AS return_category
    FROM HighValueCustomers cv
    JOIN CustomerDemographics cd ON cd.c_customer_sk = cv.customer_sk
)
SELECT 
    fr.customer_sk,
    fr.total_web_profit,
    fr.cd_gender,
    fr.cd_marital_status,
    fr.cd_dep_count,
    fr.return_category
FROM FinalReport fr
WHERE fr.cd_gender = 'F' 
AND fr.cd_dep_count > 1
ORDER BY fr.total_web_profit DESC
LIMIT 50;

