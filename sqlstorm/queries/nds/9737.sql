
WITH CustomerSales AS (
    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name, 
           SUM(s.ws_ext_sales_price) AS total_sales, 
           COUNT(DISTINCT s.ws_order_number) AS order_count
    FROM customer c
    JOIN web_sales s ON c.c_customer_sk = s.ws_bill_customer_sk
    WHERE s.ws_sold_date_sk BETWEEN 
          (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2022) - 90 AND 
          (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2022)
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
), Demographics AS (
    SELECT cd.cd_demo_sk, 
           cd.cd_gender, 
           cd.cd_marital_status, 
           cd.cd_education_status,
           ib.ib_income_band_sk
    FROM customer_demographics cd
    JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
), CustomerInsights AS (
    SELECT cs.c_customer_sk, 
           cs.c_first_name, 
           cs.c_last_name, 
           cs.total_sales, 
           cs.order_count,
           d.cd_gender, 
           d.cd_marital_status, 
           d.cd_education_status, 
           d.ib_income_band_sk
    FROM CustomerSales cs
    JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
    JOIN Demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
    WHERE cs.total_sales > 1000
)
SELECT ci.c_customer_sk, 
       ci.c_first_name, 
       ci.c_last_name, 
       ci.total_sales, 
       ci.order_count, 
       ci.cd_gender, 
       ci.cd_marital_status, 
       ci.cd_education_status, 
       ib.ib_lower_bound, 
       ib.ib_upper_bound
FROM CustomerInsights ci
JOIN income_band ib ON ci.ib_income_band_sk = ib.ib_income_band_sk
ORDER BY ci.total_sales DESC
LIMIT 10;
