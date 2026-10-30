
WITH concatenated AS (
    SELECT 
        c.c_first_name || ' ' || c.c_last_name AS full_name,
        ca.ca_city || ', ' || ca.ca_state AS full_address,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(ss.ss_ticket_number) AS sales_count
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        full_name, full_address, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
)
SELECT 
    full_name,
    full_address,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    CASE 
        WHEN sales_count = 0 THEN 'No Sales'
        WHEN sales_count BETWEEN 1 AND 5 THEN 'Low Sales'
        WHEN sales_count BETWEEN 6 AND 15 THEN 'Medium Sales'
        ELSE 'High Sales'
    END AS sales_category
FROM 
    concatenated
ORDER BY 
    sales_count DESC, full_name;
