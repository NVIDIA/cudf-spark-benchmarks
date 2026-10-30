
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        c.c_email_address,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Male'
            WHEN cd.cd_gender = 'F' THEN 'Female'
            ELSE 'Other'
        END AS gender,
        cd.cd_marital_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, c.c_email_address, 
        cd.cd_gender, cd.cd_marital_status, ca.ca_city, ca.ca_state, ca.ca_country
),
RankedCustomers AS (
    SELECT 
        cd.*, 
        ROW_NUMBER() OVER (PARTITION BY cd.gender ORDER BY cd.total_spent DESC) AS rank
    FROM 
        CustomerDetails cd
)
SELECT 
    full_name,
    c_email_address,
    gender,
    cd_marital_status,
    ca_city,
    ca_state,
    ca_country,
    total_orders,
    total_spent
FROM 
    RankedCustomers
WHERE 
    rank <= 5
ORDER BY 
    gender, total_spent DESC;
