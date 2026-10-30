
WITH top_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2450000 AND 2450500 
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
    ORDER BY 
        total_spent DESC
    LIMIT 10
),
customer_demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_dep_count,
        cd.cd_dep_employed_count
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    WHERE 
        c.c_customer_sk IN (SELECT c_customer_sk FROM top_customers)
),
address_info AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        COUNT(*) AS number_of_customers
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY 
        ca.ca_address_sk, ca.ca_city, ca.ca_state
),
demographic_summary AS (
    SELECT 
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS number_of_customers,
        AVG(cd.cd_dep_count) AS avg_dependents,
        AVG(cd.cd_dep_employed_count) AS avg_employed_dependents
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd.cd_gender
),
city_spending AS (
    SELECT 
        ai.ca_city,
        ai.ca_state,
        SUM(tc.total_spent) AS total_spent_per_city
    FROM 
        top_customers tc
    JOIN 
        address_info ai ON tc.c_customer_sk = ai.number_of_customers
    GROUP BY 
        ai.ca_city, ai.ca_state
)
SELECT 
    ds.cd_gender,
    ds.number_of_customers,
    ds.avg_dependents, 
    ds.avg_employed_dependents, 
    cs.ca_city, 
    cs.ca_state, 
    cs.total_spent_per_city
FROM 
    demographic_summary ds
JOIN 
    city_spending cs ON ds.number_of_customers > 0
ORDER BY 
    cs.total_spent_per_city DESC;
