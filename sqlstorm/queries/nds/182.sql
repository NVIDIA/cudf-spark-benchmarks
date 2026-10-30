WITH CustomerSales AS (
    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name, 
           SUM(ws.ws_net_paid) AS total_sales,
           COUNT(ws.ws_order_number) AS order_count
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2451545 AND 2451546 
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name, 
           cs.total_sales,
           cs.order_count,
           RANK() OVER (ORDER BY cs.total_sales DESC) AS rank
    FROM CustomerSales cs
    JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
)
SELECT t.c_customer_sk, 
       t.c_first_name, 
       t.c_last_name, 
       t.total_sales, 
       t.order_count,
       CASE 
           WHEN t.rank <= 5 THEN 'Top 5'
           ELSE 'Others'
       END AS customer_category,
       COALESCE((
           SELECT COUNT(DISTINCT sr_ticket_number) 
           FROM store_returns 
           WHERE sr_customer_sk = t.c_customer_sk
       ), 0) AS return_count,
       (SELECT AVG(ws.ws_net_paid) 
        FROM web_sales ws 
        WHERE ws.ws_bill_customer_sk = t.c_customer_sk
        GROUP BY ws.ws_bill_customer_sk) AS average_spent
FROM TopCustomers t
WHERE t.rank <= 10
ORDER BY t.total_sales DESC;