
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS rnk
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
high_value_customers AS (
    SELECT 
        c_customer_sk,
        cd_gender,
        cd_marital_status,
        SUM(ws_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c_customer_sk, cd_gender, cd_marital_status
    HAVING 
        SUM(ws_net_paid) > 1000
)
SELECT 
    ca.ca_country,
    COUNT(DISTINCT hvc.c_customer_sk) AS high_value_customer_count,
    SUM(rv.total_quantity) AS total_sales_quantity,
    AVG(rv.total_net_paid) AS avg_net_paid,
    STRING_AGG(DISTINCT CAST(rv.ws_item_sk AS STRING), ', ') AS top_items_sold
FROM 
    customer_address ca
LEFT JOIN 
    high_value_customers hvc ON ca.ca_address_sk = hvc.c_customer_sk
LEFT JOIN 
    ranked_sales rv ON hvc.c_customer_sk = rv.ws_item_sk
WHERE 
    ca.ca_country IS NOT NULL
GROUP BY 
    ca.ca_country
HAVING 
    COUNT(DISTINCT hvc.c_customer_sk) > 0
ORDER BY 
    high_value_customer_count DESC;
