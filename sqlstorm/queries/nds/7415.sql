
WITH CustomerSales AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name,
           SUM(ws.ws_ext_sales_price) AS total_sales
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE ws.ws_sold_date_sk BETWEEN 20220501 AND 20220531
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, cs.total_sales
    FROM CustomerSales cs
    JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
    ORDER BY cs.total_sales DESC
    LIMIT 10
),
SalesByItem AS (
    SELECT ws.ws_item_sk, SUM(ws.ws_quantity) AS total_quantity_sold
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
),
ItemDetails AS (
    SELECT i.i_item_sk, i.i_item_id, i.i_product_name, s.total_quantity_sold
    FROM item i
    JOIN SalesByItem s ON i.i_item_sk = s.ws_item_sk
    ORDER BY s.total_quantity_sold DESC
    LIMIT 5
)
SELECT tc.c_first_name, tc.c_last_name, ii.i_product_name, ii.total_quantity_sold
FROM TopCustomers tc
JOIN ItemDetails ii ON tc.c_customer_sk IN (
    SELECT DISTINCT ws.ws_bill_customer_sk 
    FROM web_sales ws
    WHERE ws.ws_item_sk IN (SELECT i.i_item_sk FROM item i)
)
ORDER BY tc.total_sales DESC, ii.total_quantity_sold DESC;
