
WITH ranked_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate IS NOT NULL
),
frequent_shoppers AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_sales_price) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
    HAVING 
        COUNT(DISTINCT ws.ws_order_number) > 5
),
customer_address_with_preferences AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        CASE 
            WHEN cd.cd_marital_status = 'M' THEN 'Married'
            ELSE 'Single or Unknown'
        END AS marital_status,
        COALESCE(SUBSTRING(c.c_first_name, 1, 1), 'N/A') AS first_initial
    FROM 
        customer_address ca
    LEFT JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ca.ca_city IS NOT NULL
)
SELECT 
    r.c_customer_sk,
    r.c_first_name,
    r.c_last_name,
    r.cd_gender,
    r.cd_marital_status,
    f.order_count,
    f.total_spent,
    COALESCE(a.ca_city, 'Unknown') AS city,
    a.marital_status AS address_marital_status,
    a.first_initial
FROM 
    ranked_customers r
JOIN 
    frequent_shoppers f ON r.c_customer_sk = f.c_customer_sk
LEFT JOIN 
    customer_address_with_preferences a ON r.c_customer_sk = a.ca_address_sk
WHERE 
    (r.purchase_rank < 10 OR f.order_count > 5) 
    AND (f.total_spent BETWEEN 100.00 AND 1000.00 OR f.total_spent IS NULL)
ORDER BY 
    f.total_spent DESC NULLS LAST;
