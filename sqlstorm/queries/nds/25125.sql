
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(ss.ss_sales_price) AS total_spent,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_purchases
    FROM 
        customer c 
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        (cd.cd_marital_status = 'M' OR cd.cd_marital_status = 'S') 
        AND (cd.cd_gender = 'M' OR cd.cd_gender = 'F')
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
RankedCustomers AS (
    SELECT 
        full_name,
        ca_city,
        ca_state,
        cd_gender,
        cd_marital_status,
        total_spent,
        total_purchases,
        RANK() OVER (PARTITION BY ca_state ORDER BY total_spent DESC) AS rank_within_state
    FROM 
        CustomerDetails
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    cd_gender,
    cd_marital_status,
    total_spent,
    total_purchases,
    rank_within_state
FROM 
    RankedCustomers
WHERE 
    rank_within_state <= 10
ORDER BY 
    ca_state, total_spent DESC;
