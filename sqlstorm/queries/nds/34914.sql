
WITH  CategorySales AS (
    SELECT i.i_item_sk AS item_id,
           i.i_item_desc AS item_description,
           SUM(ws.ws_ext_sales_price) AS total_sales,
           ROW_NUMBER() OVER (PARTITION BY i.i_item_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM item i
    LEFT JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    WHERE ws.ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY i.i_item_sk, i.i_item_desc
),
CustomerStatus AS (
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           CASE 
               WHEN cd.cd_gender = 'F' THEN 'Female'
               WHEN cd.cd_gender = 'M' THEN 'Male'
               ELSE 'Other'
           END AS gender,
           COALESCE(cd.cd_marital_status, 'Unknown') AS marital_status,
           COUNT(ws.ws_order_number) AS total_orders
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
)
SELECT cs.item_id,
       cs.item_description,
       cs.total_sales,
       cs.sales_rank,
       cust.c_first_name,
       cust.c_last_name,
       cust.gender,
       cust.marital_status,
       cust.total_orders
FROM CategorySales cs
JOIN CustomerStatus cust ON cs.total_sales > (
    SELECT AVG(total_sales) FROM CategorySales
)
WHERE cs.sales_rank <= 10
ORDER BY cs.total_sales DESC
LIMIT 20 OFFSET 5;
