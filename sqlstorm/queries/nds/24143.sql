
WITH RecursiveReturns AS (
    SELECT 
        wr_returning_customer_sk,
        wr_order_number,
        wr_return_quantity,
        wr_return_amt,
        RANK() OVER (PARTITION BY wr_returning_customer_sk ORDER BY wr_return_amt DESC) AS rank_amt
    FROM web_returns
    WHERE wr_return_quantity > 0
),
UniqueCustomers AS (
    SELECT DISTINCT
        c_customer_sk,
        c_first_name,
        c_last_name,
        c_birth_month,
        c_birth_year,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE (cd_purchase_estimate IS NOT NULL AND cd_purchase_estimate > 1000)
        OR (c_birth_month = 12 AND c_birth_year < 1990)
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM web_sales
    GROUP BY ws_bill_customer_sk
)
SELECT 
    uc.c_customer_sk,
    uc.c_first_name,
    uc.c_last_name,
    uc.cd_gender,
    SUM(COALESCE(rr.wr_return_quantity, 0)) AS total_return_quantity,
    SUM(COALESCE(rr.wr_return_amt, 0)) AS total_return_amount,
    sd.total_quantity,
    sd.total_profit,
    sd.order_count
FROM UniqueCustomers uc
LEFT JOIN RecursiveReturns rr ON uc.c_customer_sk = rr.wr_returning_customer_sk
LEFT JOIN SalesData sd ON uc.c_customer_sk = sd.ws_bill_customer_sk
GROUP BY 
    uc.c_customer_sk,
    uc.c_first_name,
    uc.c_last_name,
    uc.cd_gender,
    sd.total_quantity,
    sd.total_profit,
    sd.order_count
HAVING 
    SUM(COALESCE(rr.wr_return_quantity, 0)) > 5
ORDER BY 
    total_profit DESC
LIMIT 10;
