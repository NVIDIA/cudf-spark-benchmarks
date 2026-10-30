
WITH RECURSIVE CustomerHierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_current_cdemo_sk,
        0 AS level
    FROM 
        customer c
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL

    UNION ALL

    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ch.c_current_cdemo_sk,
        ch.level + 1
    FROM 
        customer c
    JOIN 
        CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_current_cdemo_sk
)

SELECT 
    ca.ca_city,
    COUNT(DISTINCT CASE WHEN cd.cd_marital_status = 'M' THEN c.c_customer_sk END) AS married_customers,
    COUNT(DISTINCT c.c_customer_sk) AS total_customers,
    AVG(cd.cd_purchase_estimate) AS average_purchase_estimate,
    STRING_AGG(DISTINCT cd.cd_credit_rating, ', ') AS unique_credit_ratings,
    SUM(ws.ws_net_paid) AS total_web_sales,
    SUM(COALESCE(cr.cr_return_quantity, 0)) AS total_catalog_returns,
    RANK() OVER (PARTITION BY ca.ca_state ORDER BY AVG(cd.cd_dep_count) DESC) AS state_rank
FROM 
    customer_address ca 
LEFT JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
LEFT JOIN 
    catalog_returns cr ON c.c_customer_sk = cr.cr_returning_customer_sk 
WHERE 
    ca.ca_city IS NOT NULL 
    AND ca.ca_country = 'USA' 
    AND (cd.cd_credit_rating LIKE 'A%' OR cd.cd_credit_rating IS NULL)
GROUP BY 
    ca.ca_city,
    ca.ca_state
HAVING 
    COUNT(DISTINCT c.c_customer_sk) > 10
ORDER BY 
    total_web_sales DESC
LIMIT 100;
