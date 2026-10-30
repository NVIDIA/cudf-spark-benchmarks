
WITH StringProcesses AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        TRIM(UPPER(c.c_email_address)) AS normalized_email,
        REPLACE(ca.ca_city, 'City', '') AS cleaned_city,
        LEFT(i.i_item_desc, 50) AS short_item_desc,
        CHAR_LENGTH(c.c_first_name) AS first_name_length,
        CHAR_LENGTH(c.c_last_name) AS last_name_length,
        CHAR_LENGTH(c.c_email_address) AS email_length,
        CHAR_LENGTH(i.i_item_desc) AS item_desc_length
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
)
SELECT 
    full_name,
    normalized_email,
    cleaned_city,
    short_item_desc,
    AVG(first_name_length) AS avg_first_name_length,
    AVG(last_name_length) AS avg_last_name_length,
    AVG(email_length) AS avg_email_length,
    AVG(item_desc_length) AS avg_item_desc_length
FROM 
    StringProcesses
GROUP BY 
    full_name, normalized_email, cleaned_city, short_item_desc
ORDER BY 
    avg_first_name_length DESC, avg_last_name_length DESC;
