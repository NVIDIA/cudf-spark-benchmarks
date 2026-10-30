
WITH CombinedData AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        CAST(COALESCE(NULLIF(c.c_birth_year, 0), NULL) AS STRING) AS birth_year,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_ext_sales_price) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ca.ca_city IS NOT NULL
        AND (cd.cd_gender = 'F' OR cd.cd_marital_status = 'M')
    GROUP BY 
        c.c_customer_id, full_name, ca.ca_city, ca.ca_state, ca.ca_country, cd.cd_gender, 
        cd.cd_marital_status, cd.cd_education_status, birth_year
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    ca_country,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    birth_year,
    total_orders,
    total_spent,
    CASE 
        WHEN total_spent > 1000 THEN 'HIGH_SPENDER' 
        WHEN total_spent BETWEEN 500 AND 1000 THEN 'MID_SPENDER' 
        ELSE 'LOW_SPENDER' 
    END AS spending_category
FROM 
    CombinedData
ORDER BY 
    total_spent DESC
LIMIT 100;
