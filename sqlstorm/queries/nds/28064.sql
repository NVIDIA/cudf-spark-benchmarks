
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
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
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, ca.ca_city, ca.ca_state, ca.ca_country
),
RankedCustomers AS (
    SELECT 
        ci.*,
        RANK() OVER (PARTITION BY ci.ca_country ORDER BY ci.total_spent DESC) AS country_rank
    FROM 
        CustomerInfo ci
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    total_orders,
    total_spent,
    country_rank
FROM 
    RankedCustomers
WHERE 
    country_rank <= 5
ORDER BY 
    ca_country, country_rank;
