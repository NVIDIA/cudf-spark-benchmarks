
WITH CustomerAddresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM customer_address
),
CustomerDemo AS (
    SELECT 
        cd_demo_sk,
        CONCAT(cd_gender, '-', cd_marital_status, '-', cd_education_status) AS demographics,
        cd_purchase_estimate
    FROM customer_demographics
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.demographics,
        cd.cd_purchase_estimate,
        ca.full_address
    FROM customer c
    JOIN CustomerDemo cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN CustomerAddresses ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesData AS (
    SELECT 
        c.full_name,
        COALESCE(SUM(ws.ws_sales_price), 0) AS total_web_sales,
        COALESCE(SUM(cs.cs_sales_price), 0) AS total_catalog_sales,
        COALESCE(SUM(ss.ss_sales_price), 0) AS total_store_sales
    FROM CustomerInfo c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.full_name
),
CombinedSales AS (
    SELECT 
        full_name,
        total_web_sales + total_catalog_sales + total_store_sales AS total_sales,
        total_web_sales,
        total_catalog_sales,
        total_store_sales
    FROM SalesData
)
SELECT 
    full_name,
    total_sales,
    total_web_sales,
    total_catalog_sales,
    total_store_sales
FROM CombinedSales
WHERE total_sales > (SELECT AVG(total_sales) FROM CombinedSales)
ORDER BY total_sales DESC
LIMIT 10;
