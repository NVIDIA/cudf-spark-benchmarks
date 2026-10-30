
WITH CustomerSales AS (
    SELECT c.c_customer_sk,
           SUM(COALESCE(ws.ws_net_paid, 0) + COALESCE(cs.cs_net_paid, 0) + COALESCE(ss.ss_net_paid, 0)) AS total_net_sales,
           COUNT(DISTINCT COALESCE(ws.ws_order_number, cs.cs_order_number, ss.ss_ticket_number)) AS total_orders
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk
),
TopCustomers AS (
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           cs.total_net_sales,
           cs.total_orders,
           RANK() OVER (ORDER BY cs.total_net_sales DESC) AS sales_rank
    FROM CustomerSales cs
    JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
)
SELECT tc.c_customer_sk,
       tc.c_first_name,
       tc.c_last_name,
       tc.total_net_sales,
       tc.total_orders,
       tc.sales_rank
FROM TopCustomers tc
WHERE tc.sales_rank <= 10
ORDER BY tc.total_net_sales DESC;
