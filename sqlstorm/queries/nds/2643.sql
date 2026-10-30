
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        DENSE_RANK() OVER (ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
best_customers AS (
    SELECT 
        customer_sales.*,
        cd.cd_gender,
        cd.cd_marital_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY total_sales DESC) AS gender_sales_rank
    FROM 
        customer_sales
    JOIN 
        customer_demographics cd ON customer_sales.c_customer_sk = cd.cd_demo_sk
    WHERE 
        total_sales > 1000
)
SELECT 
    bc.c_first_name,
    bc.c_last_name,
    bc.total_sales,
    bc.order_count,
    bc.cd_gender,
    bc.gender_sales_rank
FROM 
    best_customers bc
LEFT JOIN 
    customer_address ca ON bc.c_customer_sk = ca.ca_address_sk
WHERE 
    (ca.ca_state IS NOT NULL AND ca.ca_country = 'USA')
    OR (bc.cd_marital_status = 'M' AND bc.total_sales > 5000)
ORDER BY 
    bc.sales_rank, bc.total_sales DESC;
