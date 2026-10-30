
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        REPLACE(cd.cd_education_status, ' ', '-') AS education_status,
        ca.ca_city,
        ca.ca_state,
        LOWER(c.c_email_address) AS email,
        LENGTH(c.c_email_address) AS email_length
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        cd.cd_marital_status = 'M'
        AND ca.ca_state = 'CA'
),
AggregatedData AS (
    SELECT 
        full_name,
        COUNT(c_customer_id) AS customer_count,
        AVG(email_length) AS avg_email_length
    FROM 
        CustomerDetails
    GROUP BY 
        full_name
),
RankedCustomers AS (
    SELECT 
        full_name,
        customer_count,
        avg_email_length,
        RANK() OVER (ORDER BY customer_count DESC) AS rank
    FROM 
        AggregatedData
)
SELECT 
    rank,
    full_name,
    customer_count,
    avg_email_length
FROM 
    RankedCustomers
WHERE 
    rank <= 10
ORDER BY 
    rank;
