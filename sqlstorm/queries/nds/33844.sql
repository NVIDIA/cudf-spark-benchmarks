
WITH  SalesHierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM customer AS c
    JOIN web_sales AS ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        sh.c_customer_sk,
        sh.c_first_name,
        sh.c_last_name,
        sh.total_sales
    FROM SalesHierarchy AS sh
    WHERE sh.sales_rank <= 10
),
ReturnsStats AS (
    SELECT 
        sr.sr_customer_sk,
        COUNT(sr.sr_ticket_number) AS total_returns,
        SUM(sr.sr_return_amt) AS total_return_amount
    FROM store_returns AS sr
    GROUP BY sr.sr_customer_sk
),
FullStats AS (
    SELECT 
        tc.c_customer_sk,
        tc.c_first_name,
        tc.c_last_name,
        tc.total_sales,
        COALESCE(rs.total_returns, 0) AS total_returns,
        COALESCE(rs.total_return_amount, 0) AS total_return_amount,
        (tc.total_sales - COALESCE(rs.total_return_amount, 0)) AS net_sales
    FROM TopCustomers AS tc
    LEFT JOIN ReturnsStats AS rs ON tc.c_customer_sk = rs.sr_customer_sk
)
SELECT 
    fs.c_customer_sk,
    fs.c_first_name,
    fs.c_last_name,
    fs.total_sales,
    fs.total_returns,
    fs.total_return_amount,
    fs.net_sales,
    CASE
        WHEN fs.net_sales < 0 THEN 'Negative Sales'
        WHEN fs.net_sales = 0 THEN 'No Net Sales'
        ELSE 'Positive Sales'
    END AS sales_status
FROM FullStats AS fs
ORDER BY fs.net_sales DESC;
