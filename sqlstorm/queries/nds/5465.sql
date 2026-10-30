
WITH CustomerReturns AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        COUNT(DISTINCT sr_ticket_number) AS total_store_returns,
        COUNT(DISTINCT cr_order_number) AS total_catalog_returns,
        COUNT(DISTINCT wr_order_number) AS total_web_returns
    FROM customer c
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN catalog_returns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
    LEFT JOIN web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name
),
ReturnSummary AS (
    SELECT 
        CASE 
            WHEN total_store_returns > 0 THEN 'Store'
            WHEN total_catalog_returns > 0 THEN 'Catalog'
            WHEN total_web_returns > 0 THEN 'Web'
            ELSE 'None' 
        END AS return_channel,
        COUNT(CASE WHEN total_store_returns > 0 THEN 1 END) AS store_return_count,
        COUNT(CASE WHEN total_catalog_returns > 0 THEN 1 END) AS catalog_return_count,
        COUNT(CASE WHEN total_web_returns > 0 THEN 1 END) AS web_return_count,
        COUNT(*) AS total_customers
    FROM CustomerReturns
    GROUP BY return_channel
)
SELECT 
    return_channel,
    store_return_count,
    catalog_return_count,
    web_return_count,
    total_customers,
    ROUND(100.0 * total_customers / SUM(total_customers) OVER (), 2) AS percentage_of_total_customers
FROM ReturnSummary
ORDER BY total_customers DESC;
