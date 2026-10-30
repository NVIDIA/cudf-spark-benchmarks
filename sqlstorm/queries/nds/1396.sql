
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price) AS total_spent
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
HighSpendingCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_orders,
        cs.total_spent,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS spending_rank
    FROM CustomerSales cs
    JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE cs.total_spent > 1000
),
RecentReturns AS (
    SELECT 
        cr_returning_customer_sk,
        COUNT(cr_order_number) AS total_returns,
        SUM(cr_return_amount) AS total_return_amt
    FROM catalog_returns 
    GROUP BY cr_returning_customer_sk
)
SELECT 
    hsc.c_customer_sk,
    hsc.c_first_name,
    hsc.c_last_name,
    hsc.total_orders,
    hsc.total_spent,
    hsc.spending_rank,
    COALESCE(rr.total_returns, 0) AS total_returns,
    COALESCE(rr.total_return_amt, 0) AS total_return_amt
FROM HighSpendingCustomers hsc
LEFT JOIN RecentReturns rr ON hsc.c_customer_sk = rr.cr_returning_customer_sk
WHERE hsc.spending_rank <= 10
ORDER BY hsc.total_spent DESC;

