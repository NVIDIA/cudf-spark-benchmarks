
WITH RankedSales AS (
    SELECT
        ws_bill_customer_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS ranking
    FROM web_sales
    GROUP BY ws_bill_customer_sk, ws_item_sk
),
TopSales AS (
    SELECT
        r.ws_bill_customer_sk,
        i.i_item_desc,
        r.total_quantity,
        r.total_sales
    FROM RankedSales r
    JOIN item i ON r.ws_item_sk = i.i_item_sk
    WHERE r.ranking <= 5
),
CustomerDemographics AS (
    SELECT
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        cd.cd_purchase_estimate,
        cd.cd_dep_count
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_marital_status IS NOT NULL
),
PurchaseAnalysis AS (
    SELECT
        cs_bill_customer_sk,
        SUM(cs_ext_sales_price) AS total_catalog_sales,
        SUM(cs_quantity) AS total_catalog_quantity
    FROM catalog_sales
    GROUP BY cs_bill_customer_sk
)
SELECT
    s.ws_bill_customer_sk AS customer_id,
    COALESCE(cust.cd_gender, 'Unknown') AS gender,
    COALESCE(cust.cd_marital_status, 'Unknown') AS marital_status,
    s.total_quantity,
    s.total_sales,
    COALESCE(pa.total_catalog_sales, 0) AS total_catalog_sales,
    COALESCE(pa.total_catalog_quantity, 0) AS total_catalog_quantity,
    CASE 
        WHEN s.total_quantity > 100 THEN 'High Volume'
        WHEN s.total_quantity > 50 THEN 'Medium Volume'
        ELSE 'Low Volume'
    END AS purchase_category
FROM TopSales s
LEFT JOIN CustomerDemographics cust ON s.ws_bill_customer_sk = cust.c_customer_sk
LEFT JOIN PurchaseAnalysis pa ON s.ws_bill_customer_sk = pa.cs_bill_customer_sk
WHERE s.total_sales IS NOT NULL AND cust.cd_credit_rating IS NOT NULL
ORDER BY s.total_sales DESC
LIMIT 10;
