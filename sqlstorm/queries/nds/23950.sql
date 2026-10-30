WITH CustomerReturns AS (
    SELECT
        c.c_customer_id,
        COALESCE(SUM(sr_return_quantity), 0) AS total_store_returns,
        COALESCE(SUM(wr_return_quantity), 0) AS total_web_returns,
        COALESCE(SUM(cr_return_quantity), 0) AS total_catalog_returns
    FROM
        customer c
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
    LEFT JOIN catalog_returns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
    GROUP BY c.c_customer_id
),
BestCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        DENSE_RANK() OVER (ORDER BY (total_store_returns + total_web_returns + total_catalog_returns) DESC) AS rank
    FROM
        CustomerReturns cr
    JOIN customer c ON c.c_customer_id = cr.c_customer_id
    WHERE (total_store_returns + total_web_returns + total_catalog_returns) > 0
),
ReturnStatistics AS (
    SELECT 
        r.c_customer_id,
        r.total_store_returns,
        r.total_web_returns,
        r.total_catalog_returns,
        CASE 
            WHEN r.total_store_returns > r.total_web_returns AND r.total_store_returns > r.total_catalog_returns THEN 'Store'
            WHEN r.total_web_returns > r.total_catalog_returns THEN 'Web'
            ELSE 'Catalog'
        END AS preferred_return_channel
    FROM 
        CustomerReturns r
)
SELECT 
    b.c_customer_id,
    b.c_first_name,
    b.c_last_name,
    rs.total_store_returns,
    rs.total_web_returns,
    rs.total_catalog_returns,
    (CASE 
        WHEN rs.preferred_return_channel IS NULL THEN 'No Returns'
        ELSE rs.preferred_return_channel
     END) AS most_preferred_return_channel,
    (SELECT COUNT(*) FROM customer_demographics d WHERE d.cd_dep_count IS NOT NULL AND d.cd_dep_count > 0) AS dependent_customers_count
FROM 
    BestCustomers b
LEFT JOIN ReturnStatistics rs ON b.c_customer_id = rs.c_customer_id
WHERE 
    b.rank < 6   
ORDER BY 
    b.rank;