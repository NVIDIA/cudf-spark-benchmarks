
WITH CustomerSales AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           SUM(ws.ws_ext_sales_price) AS TotalSales, 
           COUNT(DISTINCT ws.ws_order_number) AS OrderCount
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2023
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
CustomerDemographics AS (
    SELECT cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, 
           cd.cd_education_status, cd.cd_purchase_estimate
    FROM customer_demographics cd
    JOIN customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
),
SalesRanked AS (
    SELECT cs.c_customer_sk, cs.c_first_name, cs.c_last_name, cs.TotalSales, cs.OrderCount,
           cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
    FROM CustomerSales cs
    JOIN CustomerDemographics cd ON cs.c_customer_sk = cd.cd_demo_sk
),
RankedSales AS (
    SELECT *, 
           ROW_NUMBER() OVER (PARTITION BY cd_gender ORDER BY TotalSales DESC) AS SalesRank
    FROM SalesRanked
)
SELECT r.c_first_name, r.c_last_name, r.TotalSales, r.OrderCount, r.cd_gender, r.cd_marital_status
FROM RankedSales r
WHERE r.SalesRank <= 10
ORDER BY r.cd_gender, r.TotalSales DESC;
