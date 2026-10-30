WITH StringAnalysis AS (
    SELECT 
        w.w_warehouse_name,
        w.w_city,
        w.w_state,
        LENGTH(w.w_warehouse_name) AS name_length,
        LENGTH(w.w_city) AS city_length,
        LENGTH(w.w_state) AS state_length,
        LOWER(w.w_warehouse_name) AS lower_name,
        UPPER(w.w_city) AS upper_city,
        CONCAT(UPPER(SUBSTRING(w.w_state, 1, 1)), LOWER(SUBSTRING(w.w_state, 2))) AS formatted_state
    FROM 
        warehouse w 
    WHERE 
        w.w_warehouse_name IS NOT NULL AND 
        w.w_city IS NOT NULL AND 
        w.w_state IS NOT NULL
),
CustomerStats AS (
    SELECT 
        cd.cd_gender,
        COUNT(*) AS customer_count,
        AVG(LENGTH(c.c_email_address)) AS avg_email_length,
        COUNT(DISTINCT c.c_customer_id) AS unique_customers
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender
)
SELECT 
    sa.w_warehouse_name,
    sa.city_length,
    sa.state_length,
    cs.cd_gender,
    cs.customer_count,
    cs.avg_email_length,
    cs.unique_customers
FROM 
    StringAnalysis sa
JOIN 
    CustomerStats cs ON (sa.formatted_state = cs.cd_gender) 
ORDER BY 
    sa.name_length DESC, 
    cs.customer_count DESC;