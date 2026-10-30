
WITH customer_data AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        ca.ca_zip,
        CASE 
            WHEN LENGTH(c.c_email_address) > 0 THEN LOWER(c.c_email_address)
            ELSE 'no_email'
        END AS email_normalized,
        LENGTH(c.c_email_address) AS email_length
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
promotional_statistics AS (
    SELECT 
        p.p_promo_id,
        p.p_promo_name,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_paid) AS total_sales
    FROM promotion p
    JOIN web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY p.p_promo_id, p.p_promo_name
),
combined_data AS (
    SELECT 
        cd.c_customer_id,
        cd.full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.ca_city,
        cd.ca_state,
        cd.ca_country,
        cd.ca_zip,
        cd.email_normalized,
        cd.email_length,
        ps.p_promo_name,
        ps.total_sales
    FROM customer_data cd
    LEFT JOIN promotional_statistics ps ON 1=1 
)
SELECT 
    cd.c_customer_id,
    cd.full_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cd.ca_city,
    cd.ca_state,
    cd.ca_country,
    cd.ca_zip,
    cd.email_normalized,
    cd.email_length,
    cd.p_promo_name,
    cd.total_sales,
    COALESCE(cd.total_sales, 0) AS total_sales_adjusted
FROM combined_data cd
WHERE cd.email_length > 0 
ORDER BY total_sales_adjusted DESC
LIMIT 100;
