
WITH CustomerReturns AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(sr_return_quantity), 0) AS total_store_returns,
        COALESCE(SUM(wr_return_quantity), 0) AS total_web_returns,
        COUNT(DISTINCT sr_ticket_number) AS store_return_count,
        COUNT(DISTINCT wr_order_number) AS web_return_count
    FROM customer c
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count
    FROM customer_demographics
),
HighValueCustomers AS (
    SELECT 
        cr.c_customer_sk, 
        cr.c_first_name, 
        cr.c_last_name, 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM CustomerReturns cr
    JOIN CustomerDemographics cd ON cr.c_customer_sk = cd.cd_demo_sk
    WHERE cr.total_store_returns + cr.total_web_returns > 10 OR cd.cd_purchase_estimate > 1000
),
IncomeBandDetails AS (
    SELECT 
        hd.hd_demo_sk,
        IB.ib_lower_bound,
        IB.ib_upper_bound
    FROM household_demographics hd
    JOIN income_band IB ON hd.hd_income_band_sk = IB.ib_income_band_sk
)
SELECT 
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.cd_gender,
    hvc.cd_marital_status,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    COUNT(ws.ws_order_number) AS total_orders,
    SUM(ws.ws_net_profit) AS total_net_profit
FROM HighValueCustomers hvc
LEFT JOIN web_sales ws ON hvc.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN IncomeBandDetails ib ON hvc.c_customer_sk = ib.hd_demo_sk
GROUP BY 
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.cd_gender,
    hvc.cd_marital_status,
    ib.ib_lower_bound,
    ib.ib_upper_bound
HAVING 
    COUNT(ws.ws_order_number) > 5
ORDER BY total_net_profit DESC
LIMIT 10;
