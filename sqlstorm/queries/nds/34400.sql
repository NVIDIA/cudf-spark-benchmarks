
WITH  SalesHierarchy AS (
    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name, 
           cs.ss_sales_price,
           cs.ss_quantity,
           cs.ss_sold_date_sk,
           ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY cs.ss_sold_date_sk DESC) AS SaleRank 
    FROM customer c
    JOIN store_sales cs ON c.c_customer_sk = cs.ss_customer_sk
    WHERE cs.ss_sold_date_sk >= (SELECT MIN(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
),
TopSales AS (
    SELECT c_customer_sk, 
           c_first_name, 
           c_last_name,
           SUM(ss_sales_price * ss_quantity) AS TotalSales 
    FROM SalesHierarchy 
    WHERE SaleRank <= 5 
    GROUP BY c_customer_sk, c_first_name, c_last_name
),
Demographics AS (
    SELECT cd.cd_demo_sk, 
           cd.cd_gender,
           cd.cd_marital_status,
           ib.ib_income_band_sk
    FROM customer_demographics cd
    LEFT JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT d.cd_gender, 
       d.cd_marital_status, 
       COALESCE(ts.TotalSales, 0) AS TotalSalesAmount
FROM Demographics d
LEFT JOIN TopSales ts ON d.cd_demo_sk = ts.c_customer_sk
WHERE d.cd_gender IS NOT NULL
  AND (d.cd_marital_status = 'M' OR d.cd_marital_status IS NULL)
ORDER BY TotalSalesAmount DESC;
