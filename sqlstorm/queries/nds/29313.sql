
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        CASE 
            WHEN cd.cd_dep_count > 0 THEN 'Has Dependents'
            ELSE 'No Dependents'
        END AS dependents_status,
        COUNT(DISTINCT ws.ws_order_number) AS total_web_orders,
        SUM(ws.ws_net_paid) AS total_web_spent
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, 
        ca.ca_city, ca.ca_state, cd.cd_gender, 
        cd.cd_marital_status, cd.cd_education_status, cd.cd_dep_count
), GenderStats AS (
    SELECT 
        ci.cd_gender,
        COUNT(*) AS customer_count,
        SUM(ci.total_web_orders) AS total_orders,
        SUM(ci.total_web_spent) AS total_spent,
        AVG(ci.total_web_spent) AS avg_spent_per_customer
    FROM 
        CustomerInfo ci
    GROUP BY 
        ci.cd_gender
)
SELECT 
    gs.cd_gender,
    gs.customer_count,
    gs.total_orders,
    gs.total_spent,
    gs.avg_spent_per_customer,
    RANK() OVER (ORDER BY gs.total_spent DESC) AS spending_rank
FROM 
    GenderStats gs
ORDER BY 
    gs.total_spent DESC;
