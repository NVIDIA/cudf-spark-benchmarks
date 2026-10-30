
WITH  sales_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ROUND(SUM(ws.ws_net_paid), 2) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d.d_date_sk FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING 
        ROUND(SUM(ws.ws_net_paid), 2) > 1000.00
    UNION ALL
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ROUND(SUM(cs.cs_net_paid), 2) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(cs.cs_net_paid) DESC) AS rank
    FROM 
        customer c
    JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    WHERE 
        cs.cs_sold_date_sk IN (SELECT d.d_date_sk FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING 
        ROUND(SUM(cs.cs_net_paid), 2) > 500.00
),
customer_addresses AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer_address ca
    LEFT JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY 
        ca.ca_address_sk, ca.ca_city, ca.ca_state
)
SELECT 
    s.c_first_name,
    s.c_last_name,
    s.total_sales,
    ca.ca_city,
    ca.ca_state,
    COALESCE(ca.customer_count, 0) AS customer_count,
    CASE 
        WHEN s.total_sales > 5000 THEN 'Platinum'
        WHEN s.total_sales > 1000 THEN 'Gold'
        ELSE 'Silver'
    END AS customer_tier
FROM 
    sales_hierarchy s
LEFT JOIN 
    customer_addresses ca ON s.c_customer_sk = ca.ca_address_sk
WHERE 
    s.rank = 1
ORDER BY 
    s.total_sales DESC
LIMIT 100;
