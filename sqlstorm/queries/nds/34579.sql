
WITH  SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        RANK() OVER (ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
TopCustomers AS (
    SELECT 
        cs_bill_customer_sk,
        SUM(cs_sales_price) AS total_catalog_sales
    FROM catalog_sales
    WHERE cs_sold_date_sk BETWEEN 20230101 AND 20231231
    GROUP BY cs_bill_customer_sk
),
CombinedSales AS (
    SELECT 
        COALESCE(ws.ws_bill_customer_sk, cs.cs_bill_customer_sk) AS customer_sk,
        COALESCE(ws.total_sales, 0) AS web_total_sales,
        COALESCE(cs.total_catalog_sales, 0) AS catalog_total_sales
    FROM SalesSummary ws
    FULL OUTER JOIN TopCustomers cs ON ws.ws_bill_customer_sk = cs.cs_bill_customer_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    cd.c_first_name,
    cd.c_last_name,
    cs.web_total_sales,
    cs.catalog_total_sales,
    (cs.web_total_sales + cs.catalog_total_sales) AS total_combined_sales,
    CASE 
        WHEN cs.web_total_sales > 0 THEN 'Web Buyer' 
        ELSE 'Catalog Buyer' 
    END AS buying_channel,
    CASE 
        WHEN (cd.cd_marital_status = 'M' AND cd.cd_gender = 'F') THEN 'Married Female'
        WHEN (cd.cd_marital_status = 'M' AND cd.cd_gender = 'M') THEN 'Married Male'
        ELSE 'Others'
    END AS marital_gender_group
FROM CombinedSales cs
JOIN CustomerDemographics cd ON cs.customer_sk = cd.c_customer_sk
WHERE (cs.web_total_sales + cs.catalog_total_sales) > 5000
ORDER BY total_combined_sales DESC
LIMIT 10;
