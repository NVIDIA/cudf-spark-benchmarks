
WITH Ranked_Customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        SUBSTRING(c.c_email_address, POSITION('@' IN c.c_email_address) + 1, LENGTH(c.c_email_address) - POSITION('@' IN c.c_email_address)) AS domain,
        COUNT(ss.ss_item_sk) AS purchase_count
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_email_address
),
Top_Domains AS (
    SELECT 
        domain,
        COUNT(*) AS domain_count
    FROM 
        Ranked_Customers
    GROUP BY 
        domain
    ORDER BY 
        domain_count DESC
    LIMIT 10
)
SELECT 
    rd.c_first_name,
    rd.c_last_name,
    rd.domain,
    td.domain_count
FROM 
    Ranked_Customers rd
JOIN 
    Top_Domains td ON rd.domain = td.domain
ORDER BY 
    td.domain_count DESC, rd.c_last_name ASC;
