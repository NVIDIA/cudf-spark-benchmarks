
WITH CustomerOrders AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, SUM(ws.ws_ext_sales_price) AS total_sales
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2023
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
), TopCustomers AS (
    SELECT c.c_customer_sk AS customer_id, c.c_first_name, c.c_last_name, co.total_sales,
           RANK() OVER (ORDER BY co.total_sales DESC) AS sales_rank
    FROM CustomerOrders co
    JOIN customer c ON co.c_customer_sk = c.c_customer_sk
    WHERE co.total_sales > 1000
), CustomerDemographics AS (
    SELECT cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, tc.total_sales
    FROM TopCustomers tc
    JOIN customer_demographics cd ON tc.customer_id = cd.cd_demo_sk
), MonthlySales AS (
    SELECT EXTRACT(MONTH FROM dd.d_date) AS sales_month, SUM(ws.ws_ext_sales_price) AS monthly_sales
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2023
    GROUP BY sales_month
)
SELECT cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, SUM(ms.monthly_sales) AS total_monthly_sales
FROM CustomerDemographics cd
JOIN MonthlySales ms ON cd.total_sales BETWEEN 1000 AND 50000
GROUP BY cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
ORDER BY total_monthly_sales DESC;
