
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM store_returns
    GROUP BY sr_customer_sk
),
SalesSummary AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_sk
),
CustomerWithReturns AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount,
        COALESCE(ss.total_sales, 0) AS total_sales,
        COALESCE(ss.total_profit, 0) AS total_profit
    FROM customer c
    LEFT JOIN CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
    LEFT JOIN SalesSummary ss ON c.c_customer_sk = ss.c_customer_sk
),
IncomeDistribution AS (
    SELECT 
        hd.hd_income_band_sk,
        COUNT(c.c_customer_sk) AS num_customers,
        AVG(COALESCE(cwr.total_sales, 0)) AS avg_sales,
        AVG(COALESCE(cwr.total_profits, 0)) AS avg_profit
    FROM household_demographics hd
    JOIN customer c ON hd.hd_demo_sk = c.c_current_hdemo_sk
    LEFT JOIN (
        SELECT 
            c_customer_sk,
            SUM(total_sales) AS total_sales,
            SUM(total_profit) AS total_profits
        FROM CustomerWithReturns
        GROUP BY c_customer_sk
    ) cwr ON c.c_customer_sk = cwr.c_customer_sk
    GROUP BY hd.hd_income_band_sk
)
SELECT 
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    id.num_customers,
    id.avg_sales,
    id.avg_profit
FROM income_band ib
JOIN IncomeDistribution id ON ib.ib_income_band_sk = id.hd_income_band_sk
WHERE id.num_customers > 0
ORDER BY ib.ib_income_band_sk;
