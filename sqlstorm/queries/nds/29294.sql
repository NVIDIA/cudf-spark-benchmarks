
WITH StringAnalysis AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        LENGTH(CONCAT(c.c_first_name, ' ', c.c_last_name)) AS name_length,
        UPPER(c.c_email_address) AS email_uppercase,
        LOWER(c.c_birth_country) AS birth_country_lowercase,
        REPLACE(c.c_email_address, '@', ' [at] ') AS email_obfuscated
    FROM 
        customer c
    WHERE 
        c.c_birth_year > 1980
),
SalesAnalysis AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_sales_price) AS total_spent,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
    HAVING 
        SUM(ws.ws_sales_price) > 500
)
SELECT 
    sa.full_name,
    sa.name_length,
    sa.email_uppercase,
    sa.birth_country_lowercase,
    sa.email_obfuscated,
    sa.c_customer_sk,
    sal.total_spent,
    sal.order_count
FROM 
    StringAnalysis sa
LEFT JOIN 
    SalesAnalysis sal 
ON 
    sa.c_customer_sk = sal.ws_bill_customer_sk
ORDER BY 
    sa.name_length DESC, sal.total_spent DESC
LIMIT 100;
