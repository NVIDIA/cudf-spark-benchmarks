
WITH enriched_customers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Male'
            WHEN cd.cd_gender = 'F' THEN 'Female'
            ELSE 'Other' 
        END AS gender,
        cd.cd_marital_status,
        ca.ca_city,
        ca.ca_state,
        SUBSTRING(c.c_email_address, POSITION('@' IN c.c_email_address) + 1) AS domain
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
customer_activity AS (
    SELECT 
        ec.c_customer_sk,
        COUNT(ws.ws_order_number) AS total_web_orders,
        COUNT(ss.ss_ticket_number) AS total_store_orders,
        COUNT(cr.cr_order_number) AS total_catalog_returns,
        COUNT(wr.wr_order_number) AS total_web_returns
    FROM 
        enriched_customers ec
    LEFT JOIN 
        web_sales ws ON ec.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON ec.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        catalog_returns cr ON ec.c_customer_sk = cr.cr_returning_customer_sk
    LEFT JOIN 
        web_returns wr ON ec.c_customer_sk = wr.wr_returning_customer_sk
    GROUP BY 
        ec.c_customer_sk
)
SELECT 
    ec.full_name,
    ec.gender,
    ec.cd_marital_status,
    ec.ca_city,
    ec.ca_state,
    ca.total_web_orders,
    ca.total_store_orders,
    ca.total_catalog_returns,
    ca.total_web_returns,
    CASE 
        WHEN ca.total_web_orders > 10 THEN 'High Engagement'
        WHEN ca.total_web_orders BETWEEN 5 AND 10 THEN 'Medium Engagement'
        ELSE 'Low Engagement' 
    END AS engagement_level
FROM 
    enriched_customers ec
JOIN 
    customer_activity ca ON ec.c_customer_sk = ca.c_customer_sk
WHERE 
    ec.cd_marital_status = 'M' 
    AND ec.ca_state = 'CA'
ORDER BY 
    ca.total_web_orders DESC, ec.full_name;
