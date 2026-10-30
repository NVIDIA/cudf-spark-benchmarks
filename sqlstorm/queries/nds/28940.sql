
WITH ranked_customers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        cd.cd_gender,
        cd.cd_marital_status,
        LENGTH(c.c_email_address) AS email_length,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_city ORDER BY LENGTH(c.c_email_address) DESC) as rank
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ca.ca_state = 'CA' 
        AND cd.cd_purchase_estimate > 1000
)
SELECT 
    rc.c_customer_id,
    rc.c_first_name,
    rc.c_last_name,
    rc.ca_city,
    rc.cd_gender,
    rc.cd_marital_status,
    rc.email_length
FROM 
    ranked_customers rc
WHERE 
    rc.rank <= 10
ORDER BY 
    rc.ca_city,
    rc.email_length DESC;
