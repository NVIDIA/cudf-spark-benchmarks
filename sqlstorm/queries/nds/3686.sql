
WITH CustomerSales AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_sales_price) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        COUNT(DISTINCT CASE WHEN ws.ws_ship_mode_sk IS NOT NULL THEN ws.ws_order_number END) AS shipped_order_count
    FROM
        customer c
    LEFT JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
HighValueCustomers AS (
    SELECT
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_web_sales,
        cs.order_count,
        cs.shipped_order_count,
        DENSE_RANK() OVER (ORDER BY cs.total_web_sales DESC) AS sales_rank
    FROM
        CustomerSales cs
    WHERE
        cs.total_web_sales > (SELECT AVG(total_web_sales) FROM CustomerSales)
),
TopCustomers AS (
    SELECT
        hvc.c_customer_sk,
        hvc.c_first_name,
        hvc.c_last_name,
        hvc.total_web_sales,
        hvc.order_count
    FROM
        HighValueCustomers hvc
    WHERE
        hvc.sales_rank <= 10
)
SELECT
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_web_sales,
    COALESCE((SELECT SUM(sr_return_amt_inc_tax)
               FROM store_returns sr
               WHERE sr.sr_customer_sk = tc.c_customer_sk), 0) AS total_returns,
    (tc.total_web_sales - COALESCE((SELECT SUM(sr_return_amt_inc_tax)
                                     FROM store_returns sr
                                     WHERE sr.sr_customer_sk = tc.c_customer_sk), 0)) AS net_sales,
    CASE
        WHEN COALESCE((SELECT SUM(sr_return_amt_inc_tax)
                       FROM store_returns sr
                       WHERE sr.sr_customer_sk = tc.c_customer_sk), 0) > 0
        THEN 'Includes Returns'
        ELSE 'No Returns'
    END AS return_status
FROM
    TopCustomers tc
ORDER BY
    tc.total_web_sales DESC;
