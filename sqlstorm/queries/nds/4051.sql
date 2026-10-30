
WITH CustomerSales AS (
    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name, 
           SUM(ws.ws_net_paid_inc_tax) AS total_spent,
           COUNT(ws.ws_order_number) AS order_count
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) 
                                  FROM date_dim d 
                                  WHERE d.d_year = 2023)
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
HighValueCustomers AS (
    SELECT cs.c_customer_sk, 
           cs.c_first_name, 
           cs.c_last_name, 
           cs.total_spent
    FROM CustomerSales cs
    WHERE cs.total_spent > (SELECT AVG(total_spent) FROM CustomerSales)
),
CustomerDemographics AS (
    SELECT cd.cd_demo_sk, 
           cd.cd_gender, 
           cd.cd_marital_status, 
           cd.cd_education_status,
           hd.hd_income_band_sk
    FROM customer_demographics cd
    JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
),
TopDemographics AS (
    SELECT hv.c_customer_sk,
           COUNT(DISTINCT cd.cd_demo_sk) AS demographic_count
    FROM HighValueCustomers hv
    JOIN CustomerDemographics cd ON hv.c_customer_sk = cd.cd_demo_sk
    GROUP BY hv.c_customer_sk
)
SELECT hv.c_customer_sk, 
       hv.c_first_name, 
       hv.c_last_name, 
       hv.total_spent, 
       d.cd_gender, 
       d.cd_marital_status, 
       d.cd_education_status, 
       td.demographic_count
FROM HighValueCustomers hv
LEFT JOIN CustomerDemographics d ON hv.c_customer_sk = d.cd_demo_sk
LEFT JOIN TopDemographics td ON hv.c_customer_sk = td.c_customer_sk
WHERE d.cd_gender IS NOT NULL
ORDER BY hv.total_spent DESC 
LIMIT 50;
