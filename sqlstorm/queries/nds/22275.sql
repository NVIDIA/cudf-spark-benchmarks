
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM web_sales
    GROUP BY ws_item_sk
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT c.c_customer_id) AS purchase_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_purchase_estimate > 1000
    GROUP BY c.c_customer_sk
    HAVING COUNT(DISTINCT c.c_customer_id) > 5
),
FrequentReturners AS (
    SELECT 
        cr_returning_customer_sk,
        COUNT(*) AS total_returns,
        AVG(cr_return_amount) AS avg_return_value
    FROM catalog_returns
    GROUP BY cr_returning_customer_sk
    HAVING COUNT(*) > 10 AND AVG(cr_return_amount) > 50
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    COALESCE(SUM(RS.total_sales), 0) AS total_web_sales,
    COALESCE(COUNT(DISTINCT HVC.c_customer_sk), 0) AS high_value_customer_count,
    COALESCE(COUNT(DISTINCT FR.cr_returning_customer_sk), 0) AS frequent_returner_count
FROM customer_address ca
LEFT JOIN RankedSales RS ON RS.ws_item_sk = ca.ca_address_sk
LEFT JOIN HighValueCustomers HVC ON HVC.c_customer_sk = ca.ca_address_sk
LEFT JOIN FrequentReturners FR ON FR.cr_returning_customer_sk = ca.ca_address_sk
WHERE ca.ca_state IS NOT NULL OR ca.ca_city IS NOT NULL
GROUP BY ca.ca_city, ca.ca_state
HAVING COALESCE(SUM(RS.total_sales), 0) > 1000 OR COALESCE(COUNT(DISTINCT HVC.c_customer_sk), 0) > 0
ORDER BY total_web_sales DESC, high_value_customer_count DESC;
