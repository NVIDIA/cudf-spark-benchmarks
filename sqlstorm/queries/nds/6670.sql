
WITH CustomerSales AS (
    SELECT c.c_customer_id, 
           SUM(ws.ws_ext_sales_price) AS total_sales,
           COUNT(DISTINCT ws.ws_order_number) AS total_orders,
           COUNT(DISTINCT ws.ws_item_sk) AS unique_items_sold
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2022
    GROUP BY c.c_customer_id
),
TopCustomers AS (
    SELECT c.c_customer_id,
           cs.total_sales,
           cs.total_orders,
           cs.unique_items_sold,
           RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM CustomerSales cs
    JOIN customer c ON c.c_customer_id = cs.c_customer_id
)

SELECT tc.c_customer_id,
       tc.total_sales,
       tc.total_orders,
       tc.unique_items_sold,
       CASE 
           WHEN tc.sales_rank <= 10 THEN 'Top 10 Customers'
           WHEN tc.sales_rank <= 50 THEN 'Top 50 Customers'
           ELSE 'Other Customers'
       END AS customer_segment
FROM TopCustomers tc
WHERE tc.total_sales > 1000
ORDER BY tc.total_sales DESC;
