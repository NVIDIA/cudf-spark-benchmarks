
WITH CustomerReturns AS (
    SELECT
        sr_customer_sk,
        COUNT(sr_ticket_number) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount,
        SUM(sr_return_quantity) AS total_return_quantity
    FROM store_returns
    GROUP BY sr_customer_sk
),
TopCustomers AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cr.total_returns,
        cr.total_return_amount,
        cr.total_return_quantity,
        DENSE_RANK() OVER (ORDER BY cr.total_return_amount DESC) AS return_rank
    FROM customer c
    JOIN CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
    WHERE cr.total_returns > 0
),
MonthlySales AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY d.d_year, d.d_month_seq
),
SalesPerformance AS (
    SELECT
        t.c_customer_sk,
        t.c_first_name,
        t.c_last_name,
        t.total_returns,
        t.total_return_amount,
        m.d_year,
        m.d_month_seq,
        m.total_sales,
        m.total_orders,
        CASE WHEN m.total_sales > 0 THEN 
            (t.total_return_amount / m.total_sales) * 100
        ELSE 0 END AS return_percentage
    FROM TopCustomers t
    JOIN MonthlySales m ON m.d_year = EXTRACT(YEAR FROM DATE '2002-10-01') 
                       AND m.d_month_seq = EXTRACT(MONTH FROM DATE '2002-10-01')
)
SELECT 
    sp.c_customer_sk,
    sp.c_first_name,
    sp.c_last_name,
    sp.total_returns,
    sp.total_return_amount,
    sp.total_sales,
    sp.total_orders,
    sp.return_percentage,
    CASE 
        WHEN sp.return_percentage >= 10 THEN 'High'
        WHEN sp.return_percentage BETWEEN 5 AND 10 THEN 'Medium'
        ELSE 'Low'
    END AS return_category
FROM SalesPerformance sp
WHERE sp.return_percentage IS NOT NULL
ORDER BY sp.return_percentage DESC;
