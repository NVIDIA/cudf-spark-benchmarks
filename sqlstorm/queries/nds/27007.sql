
WITH address_parts AS (
    SELECT 
        ca_address_sk,
        TRIM(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS full_address,
        LOWER(ca_city) AS city_lower,
        LOWER(ca_state) AS state_lower
    FROM 
        customer_address
),
demographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status
    FROM 
        customer_demographics
    WHERE 
        cd_gender = 'F' AND cd_marital_status = 'M'
),
sales_info AS (
    SELECT 
        ws_bill_customer_sk, 
        SUM(ws_ext_sales_price) AS total_spent
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
final AS (
    SELECT 
        a.full_address,
        a.city_lower,
        a.state_lower,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status,
        COALESCE(si.total_spent, 0) AS total_spent
    FROM 
        address_parts a
    JOIN 
        customer c ON a.ca_address_sk = c.c_current_addr_sk
    JOIN 
        demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
    LEFT JOIN 
        sales_info si ON c.c_customer_sk = si.ws_bill_customer_sk
)
SELECT 
    city_lower,
    state_lower,
    COUNT(*) AS customer_count,
    AVG(total_spent) AS avg_spent
FROM 
    final
WHERE 
    total_spent > 100
GROUP BY 
    city_lower,
    state_lower
ORDER BY 
    avg_spent DESC, 
    customer_count DESC;
