
WITH CustomerSales AS (
    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name, 
           SUM(ws.ws_ext_sales_price) AS total_sales,
           COUNT(ws.ws_order_number) AS total_orders
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
DemographicData AS (
    SELECT cd.cd_demo_sk, 
           cd.cd_gender, 
           cd.cd_marital_status, 
           cd.cd_education_status,
           COUNT(DISTINCT cs.cs_order_number) AS orders_count,
           SUM(cs.cs_ext_sales_price) AS total_sales,
           AVG(cs.cs_sales_price) AS avg_sale_ticket
    FROM customer_demographics cd
    JOIN catalog_sales cs ON cd.cd_demo_sk = cs.cs_bill_cdemo_sk
    GROUP BY cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
SalesRanked AS (
    SELECT cs.c_customer_sk, 
           cs.c_first_name, 
           cs.c_last_name, 
           cs.total_sales, 
           cs.total_orders,
           dd.orders_count, 
           dd.total_sales AS demo_total_sales,
           dd.avg_sale_ticket,
           RANK() OVER (PARTITION BY dd.cd_gender ORDER BY cs.total_sales DESC) AS sales_rank
    FROM CustomerSales cs
    JOIN customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
    JOIN DemographicData dd ON cd.cd_demo_sk = dd.cd_demo_sk
)
SELECT sr.c_customer_sk,
       sr.c_first_name,
       sr.c_last_name,
       sr.total_sales,
       sr.total_orders,
       sr.orders_count,
       sr.demo_total_sales,
       sr.avg_sale_ticket,
       sr.sales_rank
FROM SalesRanked sr
WHERE sr.sales_rank <= 10
ORDER BY sr.sales_rank, sr.total_sales DESC;
