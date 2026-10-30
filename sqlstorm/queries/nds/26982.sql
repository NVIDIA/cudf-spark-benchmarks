
WITH FilteredCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        LENGTH(c.c_email_address) AS email_length
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ca.ca_state = 'CA' 
        AND cd.cd_marital_status = 'M'
),
EmailStatistics AS (
    SELECT 
        AVG(email_length) AS avg_email_length,
        COUNT(*) AS total_customers
    FROM 
        FilteredCustomers
),
AddressStatistics AS (
    SELECT 
        ca_city,
        COUNT(DISTINCT c_customer_sk) AS customer_count
    FROM 
        FilteredCustomers
    GROUP BY 
        ca_city
),
FinalStatistics AS (
    SELECT 
        e.avg_email_length,
        e.total_customers,
        a.ca_city,
        a.customer_count
    FROM 
        EmailStatistics e
    CROSS JOIN 
        AddressStatistics a
)
SELECT 
    fs.avg_email_length,
    fs.total_customers,
    fs.ca_city,
    fs.customer_count,
    CASE 
        WHEN fs.total_customers > 100 THEN 'High'
        WHEN fs.total_customers BETWEEN 50 AND 100 THEN 'Medium'
        ELSE 'Low'
    END AS customer_segment
FROM 
    FinalStatistics fs
ORDER BY 
    fs.customer_count DESC;
