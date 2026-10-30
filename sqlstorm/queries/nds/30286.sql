
WITH  sales_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        s.ss_sold_date_sk,
        SUM(s.ss_net_profit) AS total_profit
    FROM 
        customer c
    JOIN 
        store_sales s ON c.c_customer_sk = s.ss_customer_sk
    WHERE 
        s.ss_sold_date_sk >= 2400 
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_email_address, s.ss_sold_date_sk
    
    UNION ALL
    
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        s.ss_sold_date_sk,
        SUM(s.ss_net_profit) AS total_profit
    FROM 
        customer c
    JOIN 
        store_sales s ON c.c_customer_sk = s.ss_customer_sk
    WHERE 
        s.ss_sold_date_sk < 2400
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_email_address, s.ss_sold_date_sk
)

SELECT 
    ca.ca_city,
    SUM(sh.total_profit) AS city_total_profit,
    COUNT(DISTINCT sh.c_customer_sk) AS unique_customers,
    MAX(sh.total_profit) AS max_profit,
    MIN(sh.total_profit) AS min_profit,
    AVG(sh.total_profit) AS avg_profit,
    CASE 
        WHEN AVG(sh.total_profit) IS NULL THEN 'No Profit'
        ELSE CAST(AVG(sh.total_profit) AS STRING)
    END AS avg_profit_string
FROM 
    sales_hierarchy sh
JOIN 
    customer_address ca ON sh.c_customer_sk = ca.ca_address_sk
LEFT JOIN 
    date_dim d ON d.d_date_sk = sh.ss_sold_date_sk
WHERE 
    d.d_year BETWEEN 1998 AND 2001
GROUP BY 
    ca.ca_city
ORDER BY 
    city_total_profit DESC
LIMIT 10;
