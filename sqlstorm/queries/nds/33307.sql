
WITH  SalesCTE AS (
    SELECT 
        ws_bill_customer_sk, 
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_item_sk) AS total_items,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rank
    FROM web_sales
    GROUP BY ws_bill_customer_sk
), 
CustomerReturns AS (
    SELECT 
        cr_returning_customer_sk,
        SUM(cr_return_amount) AS total_returned
    FROM catalog_returns
    GROUP BY cr_returning_customer_sk
),
SalesWithReturns AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(s.total_sales, 0) AS total_sales,
        COALESCE(r.total_returned, 0) AS total_returned,
        (COALESCE(s.total_sales, 0) - COALESCE(r.total_returned, 0)) AS net_sales
    FROM customer c
    LEFT JOIN SalesCTE s ON c.c_customer_sk = s.ws_bill_customer_sk
    LEFT JOIN CustomerReturns r ON c.c_customer_sk = r.cr_returning_customer_sk
)
SELECT 
    ca.ca_address_id,
    COUNT(DISTINCT c.c_customer_id) AS customer_count,
    AVG(s.net_sales) AS average_net_sales,
    MAX(s.net_sales) AS max_net_sales,
    STRING_AGG(CONCAT(c.c_first_name, ' ', c.c_last_name), '; ') AS customer_names
FROM SalesWithReturns s
JOIN customer c ON c.c_customer_sk = s.c_customer_sk
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE s.net_sales > 0 
GROUP BY ca.ca_address_id
HAVING AVG(s.net_sales) > (SELECT AVG(net_sales) FROM SalesWithReturns)
ORDER BY customer_count DESC
LIMIT 10;
