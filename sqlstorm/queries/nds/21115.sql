
WITH Customer_Returns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returns,
        COUNT(sr_ticket_number) AS return_count,
        AVG(sr_return_amt_inc_tax) AS avg_return_amt
    FROM store_returns
    GROUP BY sr_customer_sk
),
Sales_Stats AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        MAX(ws_sold_date_sk) AS last_purchase_date,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
Filtered_Customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(ss.total_quantity, 0) AS total_quantity,
        COALESCE(ss.total_net_profit, 0) AS total_net_profit
    FROM customer c
    LEFT JOIN Customer_Returns cr ON c.c_customer_sk = cr.sr_customer_sk
    LEFT JOIN Sales_Stats ss ON c.c_customer_sk = ss.customer_sk
    WHERE (c.c_birth_year < 1980 OR c.c_birth_year IS NULL)
      AND (total_returns > 10 OR total_quantity < 5)
),
Ranked_Customers AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY total_returns ORDER BY total_net_profit DESC) AS return_rank,
        DENSE_RANK() OVER (ORDER BY total_quantity DESC) AS quantity_rank
    FROM Filtered_Customers
)
SELECT 
    fc.c_customer_sk,
    fc.c_first_name,
    fc.c_last_name,
    fc.total_returns,
    fc.total_quantity,
    fc.total_net_profit,
    rc.return_rank,
    rc.quantity_rank,
    CASE 
        WHEN fc.total_net_profit > 1000 THEN 'High Value'
        WHEN fc.total_net_profit BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value
FROM Filtered_Customers fc
JOIN Ranked_Customers rc ON fc.c_customer_sk = rc.c_customer_sk
WHERE (rc.return_rank = 1 AND rc.quantity_rank <= 5)
   OR (rc.return_rank > 5 AND rc.total_returns IS NOT NULL)
ORDER BY fc.total_net_profit DESC, fc.total_returns ASC;
