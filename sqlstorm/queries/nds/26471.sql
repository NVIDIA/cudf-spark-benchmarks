
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        COUNT(DISTINCT cr.cr_order_number) AS total_catalog_returns,
        COUNT(DISTINCT wr.wr_order_number) AS total_web_returns,
        SUM(CASE WHEN wr.wr_return_quantity > 0 THEN wr.wr_return_amt ELSE 0 END) AS total_web_return_amount,
        SUM(CASE WHEN cr.cr_return_quantity > 0 THEN cr.cr_return_amount ELSE 0 END) AS total_catalog_return_amount
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        catalog_returns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
    LEFT JOIN 
        web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state
),
TotalReturns AS (
    SELECT 
        full_name,
        ca_city,
        ca_state,
        total_catalog_returns,
        total_web_returns,
        total_web_return_amount,
        total_catalog_return_amount,
        COALESCE(total_web_return_amount + total_catalog_return_amount, 0) AS total_return_amount
    FROM 
        CustomerInfo
)
SELECT 
    *,
    CASE 
        WHEN total_return_amount = 0 THEN 'No Returns'
        WHEN total_return_amount BETWEEN 1 AND 100 THEN 'Low Returns'
        WHEN total_return_amount BETWEEN 101 AND 500 THEN 'Medium Returns'
        ELSE 'High Returns'
    END AS return_category
FROM 
    TotalReturns
ORDER BY 
    total_return_amount DESC;
