WITH CustomerSales AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name,
           SUM(ws.ws_ext_sales_price) AS total_web_sales,
           COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
SalesSummary AS (
    SELECT cs.c_customer_sk, cs.c_first_name, cs.c_last_name,
           cs.total_web_sales,
           cs.total_orders,
           DENSE_RANK() OVER (ORDER BY cs.total_web_sales DESC) AS sales_rank
    FROM CustomerSales cs
    WHERE cs.total_web_sales > 1000
),
HighValueCustomers AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           COALESCE(SUM(sr.sr_return_amt), 0) AS total_return_amount
    FROM customer c
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    WHERE sr.sr_return_amt IS NOT NULL
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
)
SELECT s.c_customer_sk, s.c_first_name, s.c_last_name, 
       s.total_web_sales, s.total_orders, 
       h.total_return_amount, 
       CASE 
           WHEN h.total_return_amount > 500 THEN 'High Risk'
           ELSE 'Low Risk'
       END AS risk_category
FROM SalesSummary s
LEFT JOIN HighValueCustomers h ON s.c_customer_sk = h.c_customer_sk
WHERE s.sales_rank <= 10;