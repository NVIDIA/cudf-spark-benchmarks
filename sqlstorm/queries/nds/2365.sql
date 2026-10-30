
WITH CustomerReturns AS (
    SELECT
        sr_returned_date_sk,
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_return_quantity,
        SUM(sr_return_amt_inc_tax) AS total_return_amt
    FROM store_returns
    GROUP BY sr_returned_date_sk, sr_customer_sk
),
WebSalesStats AS (
    SELECT
        ws_bill_customer_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_net_profit) AS total_profit,
        AVG(ws_sales_price) AS avg_sales_price
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
SalesRanked AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        w.total_orders,
        w.total_profit,
        r.total_return_quantity,
        r.total_return_amt,
        RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY w.total_profit DESC) AS sales_rank
    FROM customer c
    LEFT JOIN WebSalesStats w ON c.c_customer_sk = w.ws_bill_customer_sk
    LEFT JOIN CustomerReturns r ON c.c_customer_sk = r.sr_customer_sk
),
IncomeBand AS (
    SELECT
        hd_demo_sk,
        COUNT(hd_income_band_sk) AS income_count
    FROM household_demographics
    GROUP BY hd_demo_sk
)
SELECT
    s.c_first_name || ' ' || s.c_last_name AS customer_name,
    COALESCE(s.total_profit, 0) AS total_profit,
    COALESCE(s.total_return_quantity, 0) AS total_return_quantity,
    CASE 
        WHEN s.sales_rank = 1 THEN 'Top Customer'
        WHEN s.sales_rank BETWEEN 2 AND 5 THEN 'High Value Customer'
        ELSE 'Regular Customer'
    END AS customer_category,
    ib.ib_lower_bound,
    ib.ib_upper_bound
FROM SalesRanked s
LEFT JOIN income_band ib ON s.total_profit BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
WHERE s.total_profit IS NOT NULL
ORDER BY total_profit DESC, customer_name;
