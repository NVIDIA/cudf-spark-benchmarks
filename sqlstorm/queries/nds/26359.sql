
WITH customer_sales AS (
    SELECT c.c_customer_id, 
           CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
           SUM(ws.ws_sales_price) AS total_sales
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE c.c_birth_year BETWEEN 1980 AND 1995
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name
),
sales_ranking AS (
    SELECT cs.full_name, 
           cs.total_sales,
           RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM customer_sales cs
)
SELECT sr.sales_rank, 
       sr.full_name, 
       sr.total_sales,
       CONCAT(ROUND(sr.total_sales * 0.1, 2), ' in discounts') AS projected_discount
FROM sales_ranking sr
WHERE sr.sales_rank <= 10
ORDER BY sr.sales_rank;
