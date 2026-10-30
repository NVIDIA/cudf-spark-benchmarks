
WITH RankedSales AS (
    SELECT 
        cs_bill_customer_sk,
        SUM(cs_ext_sales_price) AS total_sales,
        COUNT(DISTINCT cs_order_number) AS order_count,
        RANK() OVER (PARTITION BY cs_bill_customer_sk ORDER BY SUM(cs_ext_sales_price) DESC) AS sales_rank
    FROM catalog_sales
    GROUP BY cs_bill_customer_sk
),
CustomerData AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_birth_year) AS rn
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
HighValueCustomers AS (
    SELECT 
        cd.c_customer_sk,
        cd.c_first_name,
        cd.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cs.total_sales,
        cs.order_count
    FROM CustomerData cd
    JOIN RankedSales cs ON cd.c_customer_sk = cs.cs_bill_customer_sk
    WHERE cs.total_sales > (SELECT AVG(total_sales) FROM RankedSales)
        AND cd.cd_marital_status = 'M'
),
FrequentShippers AS (
    SELECT 
        DISTINCT ws_ship_customer_sk,
        COUNT(ws_order_number) AS total_orders
    FROM web_sales
    GROUP BY ws_ship_customer_sk
    HAVING COUNT(ws_order_number) > 5
),
PairsOfReturns AS (
    SELECT 
        cr_returning_customer_sk,
        SUM(cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_count
    FROM catalog_returns
    GROUP BY cr_returning_customer_sk
),
FinalResults AS (
    SELECT 
        hvc.c_first_name,
        hvc.c_last_name,
        hvc.total_sales,
        hvc.order_count,
        fs.total_orders,
        pr.total_return_amount,
        pr.return_count
    FROM HighValueCustomers hvc
    FULL OUTER JOIN FrequentShippers fs ON hvc.c_customer_sk = fs.ws_ship_customer_sk
    LEFT JOIN PairsOfReturns pr ON hvc.c_customer_sk = pr.cr_returning_customer_sk
)
SELECT 
    COALESCE(f.c_first_name, 'Unknown') AS first_name,
    COALESCE(f.c_last_name, 'Unknown') AS last_name,
    COALESCE(f.total_sales, 0) AS total_sales,
    COALESCE(f.order_count, 0) AS order_count,
    COALESCE(f.total_orders, 0) AS total_orders,
    COALESCE(f.total_return_amount, 0) AS total_return_amount,
    COALESCE(f.return_count, 0) AS return_count,
    CASE 
        WHEN f.total_sales > 10000 THEN 'High Value'
        WHEN f.total_sales > 0 THEN 'Medium Value'
        ELSE 'No Value'
    END AS value_category
FROM FinalResults f
WHERE f.total_sales IS NOT NULL OR f.order_count IS NOT NULL
ORDER BY f.total_sales DESC NULLS LAST;
