
WITH  CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returns,
        COUNT(DISTINCT sr_ticket_number) AS return_count,
        ROW_NUMBER() OVER (PARTITION BY sr_customer_sk ORDER BY SUM(sr_return_quantity) DESC) AS rn
    FROM store_returns
    GROUP BY sr_customer_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cr.total_returns,
        cr.return_count
    FROM customer c
    JOIN CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
    WHERE cr.total_returns > (
        SELECT AVG(total_returns) 
        FROM CustomerReturns 
        WHERE return_count > 0
    )
    ORDER BY cr.total_returns DESC
    LIMIT 10
),
DailySales AS (
    SELECT 
        d.d_date,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        AVG(ws_net_profit) AS average_profit,
        ROW_NUMBER() OVER (ORDER BY SUM(ws_ext_sales_price) DESC) AS daily_rank
    FROM web_sales
    JOIN date_dim d ON d.d_date_sk = ws_sold_date_sk
    GROUP BY d.d_date
),
UnusualSalePatterns AS (
    SELECT
        ws_item_sk,
        COUNT(ws_order_number) AS order_frequency,
        SUM(ws_net_paid_inc_tax) AS total_revenue,
        CASE 
            WHEN COUNT(ws_order_number) < 5 THEN 'Low'
            WHEN COUNT(ws_order_number) BETWEEN 5 AND 15 THEN 'Medium'
            ELSE 'High'
        END AS sale_pattern
    FROM web_sales
    GROUP BY ws_item_sk
)
SELECT 
    tc.c_customer_id,
    tc.c_first_name,
    tc.c_last_name,
    ds.d_date,
    ds.total_sales,
    ds.order_count,
    ds.average_profit,
    usp.sale_pattern,
    usp.order_frequency,
    usp.total_revenue
FROM TopCustomers tc
JOIN DailySales ds ON ds.daily_rank = 1
JOIN UnusualSalePatterns usp ON usp.total_revenue > (
    SELECT AVG(total_revenue)  
    FROM UnusualSalePatterns
)
WHERE ds.total_sales IS NOT NULL
AND (ds.total_sales - ds.average_profit) > (0.2 * ds.average_profit)
ORDER BY tc.total_returns DESC, ds.total_sales DESC;
