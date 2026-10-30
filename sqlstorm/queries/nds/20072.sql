WITH DateRange AS (
    SELECT MAX(d_date) AS max_date, MIN(d_date) AS min_date
    FROM date_dim
),
CustomerStats AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        SUM(CASE WHEN c_birth_year IS NOT NULL THEN 1 ELSE 0 END) AS known_births,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer_demographics
    LEFT JOIN customer ON cd_demo_sk = c_current_cdemo_sk
    GROUP BY cd_demo_sk, cd_gender
),
SalesComparison AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_web_sales,
        SUM(cs_sales_price) AS total_catalog_sales
    FROM web_sales
    FULL OUTER JOIN catalog_sales ON ws_item_sk = cs_item_sk
    GROUP BY ws_item_sk
),
ReturnStats AS (
    SELECT 
        cr_item_sk,
        SUM(cr_return_quantity) AS total_catalog_returns,
        SUM(wr_return_quantity) AS total_web_returns
    FROM catalog_returns
    FULL OUTER JOIN web_returns ON cr_item_sk = wr_item_sk
    GROUP BY cr_item_sk
)

SELECT 
    c.cd_gender,
    ds.total_web_sales,
    ds.total_catalog_sales,
    rs.total_catalog_returns,
    rs.total_web_returns,
    COALESCE(ds.total_web_sales, 0) - COALESCE(ds.total_catalog_sales, 0) AS sales_variance,
    (SELECT COUNT(*) FROM CustomerStats cs WHERE cs.known_births > 0 AND cs.cd_gender = c.cd_gender) AS customers_with_known_births
FROM 
    CustomerStats c
JOIN 
    SalesComparison ds ON c.cd_demo_sk = ds.ws_item_sk
LEFT JOIN 
    ReturnStats rs ON ds.ws_item_sk = rs.cr_item_sk
WHERE 
    c.avg_purchase_estimate IS NOT NULL AND 
    (c.cd_gender = 'M' OR (c.cd_gender IS NULL AND EXISTS (
        SELECT 1 FROM DateRange dr WHERE dr.max_date < cast('2002-10-01' as date)
    )))
ORDER BY 
    sales_variance DESC
LIMIT 10;