
WITH RankedSales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_order_number,
        ws_quantity,
        ws_net_profit,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS profit_rank
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') 
                              AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
),
CustomerReturns AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_quantity) AS total_returned_quantity,
        SUM(wr_return_amt) AS total_returned_amt
    FROM web_returns
    GROUP BY wr_returning_customer_sk
),
SalesAndReturns AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_sales,
        COALESCE(cr.total_returned_quantity, 0) AS total_returns,
        COALESCE(cr.total_returned_amt, 0) AS total_returned_amt,
        COALESCE(SUM(ws.ws_net_profit), 0) - COALESCE(cr.total_returned_amt, 0) AS net_profit
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN CustomerReturns cr ON c.c_customer_sk = cr.wr_returning_customer_sk
    WHERE c.c_birth_year < 2000
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cr.total_returned_quantity, cr.total_returned_amt
)
SELECT 
    s.c_customer_sk,
    s.c_first_name,
    s.c_last_name,
    s.total_sales,
    s.total_returns,
    s.total_returned_amt,
    s.net_profit
FROM SalesAndReturns s
WHERE s.net_profit > 1000
ORDER BY s.net_profit DESC
LIMIT 10;
