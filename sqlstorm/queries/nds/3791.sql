
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        SUM(COALESCE(ws.ws_net_paid, 0) + COALESCE(cs.cs_net_paid, 0) + COALESCE(ss.ss_net_paid, 0)) AS total_spent
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk, c.c_customer_id
),
SalesDemographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(cs.total_spent) AS total_spent
    FROM CustomerSales cs
    JOIN customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
    WHERE cd.cd_purchase_estimate IS NOT NULL
    GROUP BY cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
SalesRanked AS (
    SELECT 
        sd.cd_gender,
        sd.cd_marital_status,
        sd.cd_education_status,
        sd.total_spent,
        RANK() OVER (PARTITION BY sd.cd_gender, sd.cd_marital_status ORDER BY sd.total_spent DESC) AS rank
    FROM SalesDemographics sd
)
SELECT 
    sr.cd_gender,
    sr.cd_marital_status,
    sr.cd_education_status,
    sr.total_spent,
    CASE WHEN sr.rank <= 10 THEN 'Top 10' ELSE 'Other' END AS sales_category
FROM SalesRanked sr
WHERE sr.rank <= 50 OR (sr.cd_gender = 'M' AND sr.total_spent > (SELECT AVG(total_spent) FROM SalesDemographics))
ORDER BY sr.cd_gender, sr.cd_marital_status, sr.total_spent DESC;
