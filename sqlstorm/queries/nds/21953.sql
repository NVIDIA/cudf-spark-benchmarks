
WITH  CustomerReturns AS (
    SELECT 
        sr_customer_sk, 
        SUM(sr_return_quantity) AS total_returned_qty,
        SUM(sr_return_amt_inc_tax) AS total_returned_amt
    FROM store_returns
    GROUP BY sr_customer_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_purchase_estimate, 
        cd.cd_credit_rating,
        COALESCE(hd.hd_buy_potential, 'Unknown') AS buy_potential
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
ExcessiveReturns AS (
    SELECT 
        cr.sr_customer_sk,
        cr.total_returned_qty,
        cd.cd_gender,
        cd.cd_marital_status,
        CASE 
            WHEN cr.total_returned_qty > 100 THEN 'High Returner'
            ELSE 'Regular Returner'
        END AS return_type
    FROM CustomerReturns cr
    JOIN CustomerDemographics cd ON cr.sr_customer_sk = cd.c_customer_sk
)
SELECT 
    cd.c_customer_sk,
    cd.cd_gender,
    cd.cd_marital_status,
    COALESCE(sd.total_profit, 0) AS total_profit,
    COALESCE(sd.order_count, 0) AS order_count,
    er.return_type
FROM CustomerDemographics cd
LEFT JOIN SalesData sd ON cd.c_customer_sk = sd.customer_sk
LEFT JOIN ExcessiveReturns er ON cd.c_customer_sk = er.sr_customer_sk
WHERE (cd.cd_gender = 'M' OR cd.cd_gender IS NULL)
AND (er.total_returned_qty IS NULL OR er.total_returned_qty <= 50)
AND cd.cd_purchase_estimate BETWEEN 1000 AND 5000
ORDER BY total_profit DESC NULLS LAST
LIMIT 100;
