
WITH CustomerSaleSummary AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ss.ss_sales_price) AS total_sales,
        COUNT(ss.ss_ticket_number) AS number_of_transactions,
        AVG(ss.ss_sales_price) AS avg_sales_price,
        cd.cd_gender,
        cd.cd_marital_status
    FROM customer c
    JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE ss.ss_sold_date_sk BETWEEN 
      (SELECT d.d_date_sk FROM date_dim d WHERE d.d_date = '2023-01-01') AND 
      (SELECT d.d_date_sk FROM date_dim d WHERE d.d_date = '2023-12-31')
    GROUP BY 
        c.c_customer_id, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status
), GenderSales AS (
    SELECT 
        cd_gender,
        COUNT(*) AS number_of_customers,
        SUM(total_sales) AS total_sales_by_gender,
        AVG(total_sales) AS avg_sales_per_customer
    FROM CustomerSaleSummary
    GROUP BY cd_gender
), MaritalStatusSales AS (
    SELECT 
        cd_marital_status,
        COUNT(*) AS number_of_customers,
        SUM(total_sales) AS total_sales_by_marital_status,
        AVG(total_sales) AS avg_sales_per_customer
    FROM CustomerSaleSummary
    GROUP BY cd_marital_status
)
SELECT 
    gs.cd_gender,
    gs.number_of_customers AS number_of_customers_by_gender,
    gs.total_sales_by_gender,
    gs.avg_sales_per_customer AS avg_sales_by_gender,
    ms.cd_marital_status,
    ms.number_of_customers AS number_of_customers_by_marital_status,
    ms.total_sales_by_marital_status,
    ms.avg_sales_per_customer AS avg_sales_by_marital_status
FROM GenderSales gs
FULL OUTER JOIN MaritalStatusSales ms ON 1=1
ORDER BY gs.cd_gender, ms.cd_marital_status;
