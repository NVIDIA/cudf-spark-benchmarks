
WITH  Sales_CTE AS (
    SELECT ws_order_number, ws_item_sk, ws_quantity, ws_sales_price, 
           ROW_NUMBER() OVER (PARTITION BY ws_order_number ORDER BY ws_item_sk) AS rn
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
    UNION ALL
    SELECT cs_order_number, cs_item_sk, cs_quantity, cs_sales_price,
           ROW_NUMBER() OVER (PARTITION BY cs_order_number ORDER BY cs_item_sk) AS rn
    FROM catalog_sales
    WHERE cs_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
Final_Sales AS (
    SELECT s.ws_order_number AS order_num, 
           SUM(s.ws_quantity * s.ws_sales_price) AS total_sales,
           COUNT(DISTINCT s.ws_item_sk) AS unique_items,
           SUM(s.ws_ext_tax) AS total_tax
    FROM web_sales s
    LEFT JOIN warehouse w ON s.ws_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN customer c ON s.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY s.ws_order_number
    HAVING SUM(s.ws_quantity) > 100
),
Summary AS (
    SELECT f.order_num, 
           f.total_sales, 
           f.unique_items, 
           DENSE_RANK() OVER (ORDER BY f.total_sales DESC) AS sales_rank
    FROM Final_Sales f
    WHERE f.total_sales IS NOT NULL
)
SELECT s.order_num, 
       s.total_sales, 
       s.unique_items, 
       s.sales_rank,
       COALESCE(c.c_first_name, 'Unknown') AS customer_name
FROM Summary s
LEFT JOIN customer c ON s.order_num = c.c_customer_sk
WHERE s.sales_rank <= 10
ORDER BY s.total_sales DESC
