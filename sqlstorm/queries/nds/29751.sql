
WITH StringProcessed AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        LOWER(c.c_email_address) AS email_lower,
        TRIM(wp.wp_url) AS website_url,
        LENGTH(TRIM(wp.wp_url)) AS url_length
    FROM 
        customer c
    JOIN 
        web_page wp ON c.c_customer_sk = wp.wp_customer_sk
    WHERE 
        c.c_birth_country = 'USA'
        AND wp.wp_autogen_flag = 'Y'
),
CountResults AS (
    SELECT 
        full_name,
        email_lower,
        COUNT(*) AS website_count
    FROM 
        StringProcessed
    GROUP BY 
        full_name, email_lower
)
SELECT 
    full_name,
    email_lower,
    website_count,
    COUNT(*) OVER (PARTITION BY website_count) AS frequency_count
FROM 
    CountResults
ORDER BY 
    website_count DESC, 
    frequency_count ASC;
