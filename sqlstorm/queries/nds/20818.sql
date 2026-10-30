
WITH CustomerSales AS (
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           SUM(COALESCE(ws.ws_net_paid, 0) + COALESCE(cs.cs_net_paid, 0) + COALESCE(ss.ss_net_paid, 0)) AS total_sales,
           COUNT(DISTINCT CASE WHEN ws.ws_order_number IS NOT NULL THEN ws.ws_order_number END) AS web_orders,
           COUNT(DISTINCT CASE WHEN cs.cs_order_number IS NOT NULL THEN cs.cs_order_number END) AS catalog_orders,
           COUNT(DISTINCT CASE WHEN ss.ss_ticket_number IS NOT NULL THEN ss.ss_ticket_number END) AS store_orders
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
RankedSales AS (
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           cs.total_sales,
           RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank,
           DENSE_RANK() OVER (PARTITION BY c.c_birth_year ORDER BY cs.total_sales DESC) AS year_sales_rank
    FROM CustomerSales cs
    JOIN customer c ON c.c_customer_sk = cs.c_customer_sk
),
FilteredSales AS (
    SELECT r.c_customer_sk,
           r.c_first_name,
           r.c_last_name,
           r.total_sales
    FROM RankedSales r
    WHERE r.sales_rank <= 10
    AND EXISTS (
        SELECT 1
        FROM customer_demographics cd
        WHERE cd.cd_demo_sk = r.c_customer_sk -- fixed this line
        AND cd.cd_gender = 'F'
        AND cd.cd_marital_status = 'M'
    )
)
SELECT fs.c_first_name || ' ' || fs.c_last_name AS full_name,
       fs.total_sales,
       CASE
           WHEN fs.total_sales > 1000 THEN 'High Value'
           WHEN fs.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
           ELSE 'Low Value'
       END AS customer_value,
       DENSE_RANK() OVER (ORDER BY NULLIF(fs.total_sales, 0) DESC) AS sales_value_rank
FROM FilteredSales fs
ORDER BY fs.total_sales DESC
LIMIT 5;
