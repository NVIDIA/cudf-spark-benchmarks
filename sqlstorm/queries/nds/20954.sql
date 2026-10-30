
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS rn
    FROM web_sales
    WHERE ws_sales_price IS NOT NULL
), TotalReturns AS (
    SELECT 
        cr_item_sk,
        SUM(cr_return_quantity) AS total_returned,
        SUM(cr_return_amount) AS total_return_amount
    FROM catalog_returns
    GROUP BY cr_item_sk
), CustomerStats AS (
    SELECT
        c.c_customer_sk,
        SUM(CASE WHEN cd_gender = 'F' THEN 1 ELSE 0 END) AS female_count,
        SUM(CASE WHEN cd_marital_status = 'M' THEN 1 ELSE 0 END) AS married_count,
        COUNT(*) as total_count
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY c.c_customer_sk
)
SELECT 
    COALESCE(cs.female_count, 0) AS female_customers,
    COALESCE(cs.married_count, 0) AS married_customers,
    MAX(ts.total_returned) AS max_returns,
    SUM(CASE WHEN rs.rn = 1 THEN rs.ws_sales_price ELSE 0 END) AS highest_sales_value,
    COUNT(DISTINCT cs.c_customer_sk) FILTER (WHERE cs.total_count > 5) AS active_customers
FROM CustomerStats cs
FULL OUTER JOIN TotalReturns ts ON cs.c_customer_sk = ts.cr_item_sk
FULL OUTER JOIN RankedSales rs ON ts.cr_item_sk = rs.ws_item_sk
WHERE (cs.total_count IS NULL OR cs.total_count < 10 OR cs.total_count IS NULL)
AND (rs.ws_sales_price BETWEEN 50 AND 100 OR rs.ws_sales_price IS NULL)
GROUP BY cs.female_count, cs.married_count
HAVING MAX(ts.total_return_amount) > 500
ORDER BY female_customers DESC, married_customers DESC
LIMIT 100 OFFSET 10;
