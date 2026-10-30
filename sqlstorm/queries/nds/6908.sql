WITH CustomerSales AS (
    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name, 
           SUM(ws.ws_net_profit) AS total_profit,
           COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE ws.ws_sold_date_sk BETWEEN 20150101 AND 20151231
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name, 
           cs.total_profit, 
           cs.order_count,
           RANK() OVER (ORDER BY cs.total_profit DESC) AS profit_rank
    FROM CustomerSales cs
    JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
)
SELECT tc.c_customer_sk, 
       tc.c_first_name, 
       tc.c_last_name, 
       tc.total_profit, 
       tc.order_count
FROM TopCustomers tc
WHERE tc.profit_rank <= 10
ORDER BY tc.total_profit DESC;