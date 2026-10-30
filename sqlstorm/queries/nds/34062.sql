
WITH  CustomerSales AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           SUM(ws.ws_net_paid) AS total_sales, 
           RANK() OVER (ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank
    FROM customer c
    LEFT JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT c_customer_sk, c_first_name, c_last_name, total_sales
    FROM CustomerSales
    WHERE sales_rank <= 10
),
SalesDetail AS (
    SELECT ws.ws_order_number, 
           SUM(ws.ws_quantity) AS total_quantity, 
           SUM(ws.ws_ext_sales_price) AS total_sales_value
    FROM web_sales ws
    GROUP BY ws.ws_order_number
),
ReturnedSales AS (
    SELECT cr_order_number, 
           SUM(cr_return_quantity) AS total_returned_quantity, 
           SUM(cr_return_amount) AS total_returned_value
    FROM catalog_returns
    GROUP BY cr_order_number
)
SELECT tc.c_first_name,
       tc.c_last_name,
       tc.total_sales,
       COALESCE(sd.total_quantity, 0) AS total_quantity_sold,
       COALESCE(sd.total_sales_value, 0) AS total_sales_value,
       COALESCE(rs.total_returned_quantity, 0) AS total_returned_quantity,
       COALESCE(rs.total_returned_value, 0) AS total_returned_value,
       (COALESCE(sd.total_sales_value, 0) - COALESCE(rs.total_returned_value, 0)) AS net_sales_value
FROM TopCustomers tc
LEFT JOIN SalesDetail sd ON tc.c_customer_sk = sd.ws_order_number
LEFT JOIN ReturnedSales rs ON sd.ws_order_number = rs.cr_order_number
ORDER BY tc.total_sales DESC;
