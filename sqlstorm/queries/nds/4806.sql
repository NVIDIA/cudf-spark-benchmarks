
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount
    FROM store_returns
    GROUP BY sr_customer_sk
),
RecentSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(ws_order_number) AS total_orders
    FROM web_sales
    WHERE ws_ship_date_sk > (
        SELECT MAX(ws_ship_date_sk) - 30 
        FROM web_sales
    )
    GROUP BY ws_bill_customer_sk
),
CustomerDemographicsAnalyze AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount,
        COALESCE(rs.total_profit, 0) AS total_profit,
        COALESCE(rs.total_orders, 0) AS total_orders
    FROM customer_demographics cd
    LEFT JOIN CustomerReturns cr ON cd.cd_demo_sk = cr.sr_customer_sk
    LEFT JOIN RecentSales rs ON cd.cd_demo_sk = rs.ws_bill_customer_sk
)
SELECT 
    c.c_customer_id,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_purchase_estimate,
    cd.cd_credit_rating,
    cd.total_returns,
    cd.total_return_amount,
    cd.total_profit,
    cd.total_orders,
    RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.total_profit DESC) AS gender_rank
FROM customer c
JOIN CustomerDemographicsAnalyze cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE cd.total_orders > 5
AND cd.cd_purchase_estimate BETWEEN 1000 AND 5000
AND (cd.total_returns IS NULL OR cd.total_returns < 10)
ORDER BY cd.total_profit DESC, c.c_customer_id
LIMIT 100;
