
WITH RecentPurchases AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           SUM(ws.ws_ext_sales_price) AS total_sales
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2023 AND d.d_month_seq BETWEEN 1 AND 3
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
), CustomerDemographics AS (
    SELECT cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, 
           cd.cd_education_status, cd.cd_purchase_estimate
    FROM customer_demographics cd
    WHERE cd.cd_credit_rating = 'Excellent'
), TopCustomers AS (
    SELECT rp.c_customer_sk, rp.c_first_name, rp.c_last_name, rp.total_sales
    FROM RecentPurchases rp
    ORDER BY rp.total_sales DESC
    LIMIT 10
)
SELECT tc.c_first_name, tc.c_last_name, cd.cd_gender, cd.cd_marital_status, 
       cd.cd_education_status, cd.cd_purchase_estimate, tc.total_sales 
FROM TopCustomers tc
JOIN customer c ON tc.c_customer_sk = c.c_customer_sk
JOIN CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
ORDER BY tc.total_sales DESC;
