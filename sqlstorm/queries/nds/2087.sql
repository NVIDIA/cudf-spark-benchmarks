
WITH CustomerSales AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        COUNT(DISTINCT ws.ws_web_page_sk) AS unique_page_views
    FROM customer AS c
    JOIN web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim AS d WHERE d.d_year = 2023)
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
CustomerReturns AS (
    SELECT
        sr.sr_customer_sk,
        COUNT(DISTINCT sr.sr_ticket_number) AS return_count,
        SUM(sr.sr_return_amt) AS total_return_amount
    FROM store_returns AS sr
    WHERE sr.sr_returned_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim AS d WHERE d.d_year = 2023)
    GROUP BY sr.sr_customer_sk
),
SalesWithReturns AS (
    SELECT
        cs.c_customer_sk,
        cs.total_sales,
        cs.order_count,
        COALESCE(cr.return_count, 0) AS return_count,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount
    FROM CustomerSales AS cs
    LEFT JOIN CustomerReturns AS cr ON cs.c_customer_sk = cr.sr_customer_sk
),
RankedSales AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM SalesWithReturns
),
AggregateMetrics AS (
    SELECT
        AVG(total_sales) AS avg_sales,
        AVG(order_count) AS avg_orders,
        SUM(return_count) AS total_returns,
        SUM(total_return_amount) AS total_return_value
    FROM RankedSales
)
SELECT
    rs.c_customer_sk,
    rs.total_sales,
    rs.order_count,
    rs.return_count,
    rs.total_return_amount,
    am.avg_sales,
    am.avg_orders,
    am.total_returns,
    am.total_return_value
FROM RankedSales AS rs
CROSS JOIN AggregateMetrics AS am
WHERE rs.sales_rank <= 10
ORDER BY rs.total_sales DESC;
