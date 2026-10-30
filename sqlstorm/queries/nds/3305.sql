
WITH CustomerReturns AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_quantity) AS total_returned,
        SUM(wr_return_amt_inc_tax) AS total_return_amt
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
),
TopReturningCustomers AS (
    SELECT 
        wr_returning_customer_sk,
        total_returned,
        total_return_amt,
        RANK() OVER (ORDER BY total_returned DESC) AS rank
    FROM 
        CustomerReturns
),
SalesSummary AS (
    SELECT 
        ws_ship_customer_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    WHERE 
        ws_ship_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_ship_customer_sk
)
SELECT 
    c.c_customer_id,
    COALESCE(s.total_profit, 0) AS total_profit,
    COALESCE(t.total_returned, 0) AS total_returned,
    COALESCE(t.total_return_amt, 0) AS total_return_amt
FROM 
    customer c
LEFT JOIN 
    SalesSummary s ON c.c_customer_sk = s.ws_ship_customer_sk
LEFT JOIN 
    TopReturningCustomers t ON c.c_customer_sk = t.wr_returning_customer_sk
WHERE 
    c.c_current_cdemo_sk IS NOT NULL 
    AND (s.total_profit > 500 OR t.rank <= 10)
ORDER BY 
    total_profit DESC, 
    total_returned DESC
LIMIT 100;
