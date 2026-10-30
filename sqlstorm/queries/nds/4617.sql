
WITH RankedSales AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_profit,
        DENSE_RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM
        customer c
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT
        c_customer_sk AS customer_sk,
        c_first_name,
        c_last_name,
        total_profit
    FROM
        RankedSales
    WHERE
        profit_rank = 1
),
ReturnStatistics AS (
    SELECT
        sr_customer_sk,
        COUNT(*) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount
    FROM
        store_returns
    GROUP BY
        sr_customer_sk
)
SELECT
    tc.c_first_name,
    tc.c_last_name,
    tc.total_profit,
    COALESCE(rs.total_returns, 0) AS total_returns,
    COALESCE(rs.total_return_amount, 0) AS total_return_amount,
    CASE 
        WHEN tc.total_profit > 1000 THEN 'High Value'
        WHEN tc.total_profit <= 1000 AND tc.total_profit >= 500 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM
    TopCustomers tc
LEFT JOIN
    ReturnStatistics rs ON tc.customer_sk = rs.sr_customer_sk
ORDER BY
    tc.total_profit DESC;
