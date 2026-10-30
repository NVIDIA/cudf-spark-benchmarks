
WITH customer_return_data AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(sr_return_quantity), 0) AS total_returns,
        COALESCE(SUM(sr_return_amt_inc_tax), 0) AS total_return_amount,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM customer c
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_sales_price) AS total_sales_amount,
        SUM(ws_ext_discount_amt) AS total_discount,
        AVG(ws_net_profit) AS average_profit
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
combined_data AS (
    SELECT 
        cr.c_customer_sk,
        cr.c_first_name,
        cr.c_last_name,
        cr.total_returns,
        cr.total_return_amount,
        cr.return_count,
        ss.total_orders,
        ss.total_sales_amount,
        ss.total_discount,
        ss.average_profit
    FROM customer_return_data cr
    LEFT JOIN sales_summary ss ON cr.c_customer_sk = ss.ws_bill_customer_sk
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    COALESCE(cr.total_returns, 0) AS total_returns,
    COALESCE(cr.total_return_amount, 0) AS total_return_amount,
    COALESCE(ss.total_orders, 0) AS total_orders,
    COALESCE(ss.total_sales_amount, 0) AS total_sales_amount,
    COALESCE(ss.total_discount, 0) AS total_discount,
    COALESCE(ss.average_profit, 0) AS average_profit
FROM combined_data c
LEFT JOIN customer_return_data cr ON c.c_customer_sk = cr.c_customer_sk
LEFT JOIN sales_summary ss ON c.c_customer_sk = ss.ws_bill_customer_sk
ORDER BY cr.total_return_amount DESC, ss.total_sales_amount DESC
LIMIT 100;
