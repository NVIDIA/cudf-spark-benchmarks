
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        d.d_year,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        ca.ca_state,
        SUM(web_sales.ws_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        web_sales ON c.c_customer_sk = web_sales.ws_bill_customer_sk 
    LEFT JOIN 
        date_dim d ON web_sales.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2018 AND 2023
    GROUP BY 
        c.c_customer_sk, c.c_customer_id, d.d_year, cd.cd_gender, cd.cd_marital_status, ca.ca_city, ca.ca_state
),
ranked_customers AS (
    SELECT 
        ci.*,
        RANK() OVER (PARTITION BY ci.d_year ORDER BY ci.total_spent DESC) AS spending_rank
    FROM 
        customer_info ci
)
SELECT 
    rc.c_customer_id,
    rc.d_year,
    rc.cd_gender,
    rc.cd_marital_status,
    rc.ca_city,
    rc.ca_state,
    rc.total_spent,
    rc.spending_rank
FROM 
    ranked_customers rc
WHERE 
    rc.spending_rank <= 10
ORDER BY 
    rc.d_year, rc.spending_rank;
