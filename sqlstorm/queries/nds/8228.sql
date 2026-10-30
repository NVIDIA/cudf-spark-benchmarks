
WITH customer_sales AS (
    SELECT c.c_customer_sk, 
           SUM(ws.ws_ext_sales_price) AS total_sales, 
           COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
                                  AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY c.c_customer_sk
), 
demographic_analysis AS (
    SELECT cd.cd_demo_sk, 
           cd.cd_gender, 
           cd.cd_marital_status, 
           cd.cd_education_status, 
           cd.cd_purchase_estimate, 
           COUNT(cs.c_customer_sk) AS customer_count,
           SUM(cs.total_sales) AS total_sales
    FROM customer_demographics cd
    LEFT JOIN customer_sales cs ON cd.cd_demo_sk = cs.c_customer_sk
    GROUP BY cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, cd.cd_purchase_estimate
), 
sales_summary AS (
    SELECT da.cd_gender, 
           da.cd_marital_status, 
           da.cd_education_status, 
           SUM(da.total_sales) AS total_sales_by_demo,
           SUM(da.customer_count) AS total_customers
    FROM demographic_analysis da
    GROUP BY da.cd_gender, da.cd_marital_status, da.cd_education_status
)
SELECT ss.cd_gender, 
       ss.cd_marital_status, 
       ss.cd_education_status, 
       ss.total_sales_by_demo, 
       ss.total_customers,
       (ss.total_sales_by_demo / NULLIF(ss.total_customers, 0)) AS avg_sales_per_customer
FROM sales_summary ss
ORDER BY ss.total_sales_by_demo DESC;
