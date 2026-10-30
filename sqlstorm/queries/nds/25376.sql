
SELECT 
    c.c_first_name, 
    c.c_last_name, 
    ca.ca_city, 
    ca.ca_state, 
    SUM(
        CASE 
            WHEN LENGTH(wp.wp_url) > 30 THEN 1 
            ELSE 0 
        END
    ) AS long_url_count,
    AVG(
        LENGTH(wp.wp_url)
    ) AS avg_url_length,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
WHERE 
    c.c_birth_year BETWEEN 1980 AND 1990
GROUP BY 
    c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state
HAVING 
    SUM(
        CASE 
            WHEN LENGTH(wp.wp_url) > 30 THEN 1 
            ELSE 0 
        END
    ) > 2
ORDER BY 
    total_orders DESC, avg_url_length DESC;
