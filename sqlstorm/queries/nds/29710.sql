
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, 
        cd.cd_marital_status, cd.cd_education_status, ca.ca_city, 
        ca.ca_state, ca.ca_country
),
EducationAnalysis AS (
    SELECT 
        ci.cd_education_status,
        COUNT(DISTINCT ci.c_customer_id) AS customer_count,
        AVG(ci.total_spent) AS average_spent
    FROM 
        CustomerInfo ci
    GROUP BY 
        ci.cd_education_status
)

SELECT 
    ea.cd_education_status,
    ea.customer_count,
    ea.average_spent,
    CONCAT('Total Customers: ', ea.customer_count, ', Average Spending: $', ROUND(ea.average_spent, 2)) AS summary
FROM 
    EducationAnalysis ea
ORDER BY 
    ea.average_spent DESC;
