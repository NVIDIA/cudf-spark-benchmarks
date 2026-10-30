
WITH CustomerData AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, 
        ca.ca_city, 
        ca.ca_state, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status, 
        c.c_first_name, 
        c.c_last_name
), FilteredCustomers AS (
    SELECT 
        full_name,
        ca_city,
        ca_state,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        total_orders,
        total_spent,
        RANK() OVER (PARTITION BY ca_state ORDER BY total_spent DESC) AS state_rank
    FROM 
        CustomerData
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    total_orders,
    total_spent,
    state_rank
FROM 
    FilteredCustomers
WHERE 
    total_orders > 5 AND 
    state_rank <= 10
ORDER BY 
    ca_state, state_rank;
