
WITH RankedSales AS (
    SELECT 
        cs_item_sk,
        SUM(cs_sales_price) AS total_sales,
        COUNT(DISTINCT cs_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY cs_item_sk ORDER BY SUM(cs_sales_price) DESC) AS sales_rank
    FROM catalog_sales
    WHERE cs_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY cs_item_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY cd.cd_purchase_estimate DESC) AS demo_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT 
    R.cs_item_sk,
    R.total_sales,
    C.cd_gender,
    C.cd_marital_status,
    C.cd_education_status,
    C.ib_lower_bound,
    C.ib_upper_bound
FROM RankedSales R
JOIN CustomerDemographics C ON R.cs_item_sk = C.c_customer_sk
WHERE R.sales_rank <= 10 AND C.demo_rank = 1
ORDER BY R.total_sales DESC
LIMIT 100;
