
WITH  SalesHierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           SUM(ws.ws_net_profit) AS total_profit, 
           ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rn
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2022)
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopSales AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name
    FROM SalesHierarchy c
    WHERE c.rn <= 5
),
ReturnStats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS return_count,
        SUM(sr_return_amt_inc_tax) AS total_return_amt
    FROM store_returns sr
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_sk
),
AggregatedSales AS (
    SELECT 
        sh.c_customer_sk,
        sh.total_profit,
        COALESCE(rs.return_count, 0) AS return_count,
        COALESCE(rs.total_return_amt, 0) AS total_return_amount,
        CASE 
            WHEN COALESCE(rs.total_return_amt, 0) > sh.total_profit THEN 'Loss'
            ELSE 'Profit'
        END AS profitability_status
    FROM SalesHierarchy sh
    LEFT JOIN ReturnStats rs ON sh.c_customer_sk = rs.c_customer_sk
)
SELECT 
    a.c_customer_sk,
    a.total_profit,
    a.return_count,
    a.total_return_amount,
    a.profitability_status,
    CONCAT(a.c_customer_sk, ' - ', a.total_profit) AS customer_profit_string
FROM AggregatedSales a
WHERE a.total_profit > 1000
ORDER BY a.total_profit DESC
LIMIT 10;
