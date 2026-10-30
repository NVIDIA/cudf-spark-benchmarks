
WITH customer_activity AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(COALESCE(ws.ws_quantity, 0) + COALESCE(cs.cs_quantity, 0) + COALESCE(ss.ss_quantity, 0)) AS total_quantity,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_order_count,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
demographics_summary AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ca.ca_address_sk) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS average_purchase_estimate,
        MAX(cd.cd_dep_count) AS max_dependents
    FROM 
        customer_demographics cd
    LEFT JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
)
SELECT 
    a.c_first_name,
    a.c_last_name,
    a.total_quantity,
    d.cd_gender,
    d.cd_marital_status,
    d.customer_count,
    d.average_purchase_estimate,
    d.max_dependents
FROM 
    customer_activity a
JOIN 
    demographics_summary d ON (d.customer_count > 0 AND (a.total_quantity > 100 OR d.average_purchase_estimate IS NOT NULL))
WHERE 
    (d.cd_gender = 'M' AND d.cd_marital_status = 'S') 
    OR (d.cd_gender = 'F' AND d.cd_marital_status IS NULL)
ORDER BY 
    a.total_quantity DESC
LIMIT 50;
