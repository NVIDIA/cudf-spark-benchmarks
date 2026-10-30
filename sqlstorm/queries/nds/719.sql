
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_amt) AS total_return_amt,
        COUNT(sr_ticket_number) AS total_returns,
        AVG(sr_return_quantity) AS avg_return_quantity
    FROM store_returns
    GROUP BY sr_customer_sk
), PurchaseStats AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_spent,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_quantity) AS total_quantity
    FROM web_sales
    GROUP BY ws_bill_customer_sk
), JoinedStats AS (
    SELECT 
        COALESCE(cr.sr_customer_sk, ps.ws_bill_customer_sk) AS customer_sk,
        COALESCE(total_return_amt, 0) AS total_return_amt,
        COALESCE(total_spent, 0) AS total_spent,
        total_orders,
        total_quantity
    FROM CustomerReturns cr
    FULL OUTER JOIN PurchaseStats ps ON cr.sr_customer_sk = ps.ws_bill_customer_sk
), RankedStats AS (
    SELECT 
        customer_sk,
        total_return_amt,
        total_spent,
        total_orders,
        total_quantity,
        RANK() OVER (ORDER BY total_spent DESC) AS rank_by_spending,
        RANK() OVER (ORDER BY total_return_amt DESC) AS rank_by_returns
    FROM JoinedStats
)
SELECT 
    rs.customer_sk,
    COALESCE(c.c_first_name || ' ' || c.c_last_name, 'Unknown') AS customer_name,
    total_return_amt,
    total_spent,
    total_orders,
    total_quantity,
    rank_by_spending,
    rank_by_returns,
    CASE 
        WHEN total_quantity > 0 THEN total_spent / total_quantity
        ELSE NULL
    END AS avg_spent_per_item
FROM RankedStats rs
LEFT JOIN customer c ON rs.customer_sk = c.c_customer_sk
WHERE 
    total_spent > 1000 OR total_return_amt > 50
ORDER BY total_spent DESC, total_return_amt ASC;
