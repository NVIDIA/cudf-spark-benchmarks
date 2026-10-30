
WITH FilteredCustomers AS (
    SELECT 
        c.c_customer_id, 
        c.c_first_name, 
        c.c_last_name, 
        ca.ca_city, 
        ca.ca_state,
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status,
        LENGTH(c.c_email_address) AS email_length,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'F' 
        AND ca.ca_state IN ('NY', 'CA', 'TX') 
        AND cd.cd_marital_status = 'M'
), CountDetails AS (
    SELECT 
        ca.ca_city,
        COUNT(*) AS customer_count,
        AVG(email_length) AS avg_email_length
    FROM 
        FilteredCustomers fc
    JOIN 
        customer_address ca ON fc.c_customer_id = ca.ca_address_id
    GROUP BY 
        ca.ca_city
)
SELECT 
    cd.ca_city, 
    cd.customer_count, 
    cd.avg_email_length,
    CASE 
        WHEN cd.customer_count > 100 THEN 'High'
        WHEN cd.customer_count BETWEEN 50 AND 100 THEN 'Medium'
        ELSE 'Low'
    END AS customer_category
FROM 
    CountDetails cd
ORDER BY 
    cd.customer_count DESC;
