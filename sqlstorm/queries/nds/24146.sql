WITH CustomerReturns AS (
    SELECT sr_customer_sk AS customer_key,
           COUNT(DISTINCT sr_ticket_number) AS total_returns,
           SUM(sr_return_quantity) AS total_return_quantity,
           SUM(sr_return_amt) AS total_return_amount,
           CASE 
               WHEN COUNT(DISTINCT sr_ticket_number) > 0 THEN SUM(sr_return_amt) / COUNT(DISTINCT sr_ticket_number)
               ELSE 0 
           END AS avg_return_amount_per_ticket
    FROM store_returns
    GROUP BY sr_customer_sk
),
HighReturnCustomers AS (
    SELECT customer_key,
           total_returns,
           total_return_quantity,
           avg_return_amount_per_ticket,
           DENSE_RANK() OVER (ORDER BY total_returns DESC) AS rnk
    FROM CustomerReturns
    WHERE total_return_quantity > 5
),
FrequentBuyers AS (
    SELECT ws_bill_customer_sk AS customer_key,
           COUNT(DISTINCT ws_order_number) AS total_orders,
           SUM(ws_sales_price) AS total_spent,
           CASE 
               WHEN SUM(ws_sales_price) > 0 THEN SUM(ws_sales_price) / COUNT(DISTINCT ws_order_number)
               ELSE 0 
           END AS avg_spent_per_order
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
ProminentCustomers AS (
    SELECT c.c_customer_id,
           c.c_first_name,
           c.c_last_name,
           COALESCE(HighReturnCustomers.total_returns, 0) AS return_count,
           COALESCE(FrequentBuyers.total_orders, 0) AS order_count,
           COALESCE(HighReturnCustomers.avg_return_amount_per_ticket, 0) AS avg_return_amount,
           COALESCE(FrequentBuyers.avg_spent_per_order, 0) AS avg_spent
    FROM customer c
    LEFT JOIN HighReturnCustomers ON c.c_customer_sk = HighReturnCustomers.customer_key
    LEFT JOIN FrequentBuyers ON c.c_customer_sk = FrequentBuyers.customer_key
    WHERE (COALESCE(HighReturnCustomers.total_returns, 0) > 10 OR COALESCE(FrequentBuyers.total_orders, 0) > 10)
)
SELECT p.c_customer_id,
       p.c_first_name,
       p.c_last_name,
       p.return_count,
       p.order_count,
       p.avg_return_amount,
       p.avg_spent,
       CASE 
           WHEN p.return_count > p.order_count THEN 'Risky Customer'
           WHEN p.avg_return_amount > p.avg_spent THEN 'Return Risk'
           ELSE 'Regular Customer'
       END AS customer_status,
       CASE 
           WHEN (p.return_count > 5 AND p.order_count < 2) THEN 'High Return, Low Spend'
           ELSE NULL
       END AS segment
FROM ProminentCustomers p
ORDER BY p.return_count DESC, p.order_count DESC
LIMIT 50;