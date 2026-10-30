
WITH customer_summary AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(DISTINCT sa.ca_address_id) AS address_count,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_net_profit,
        COALESCE(SUM(cr.cr_net_loss), 0) AS total_net_loss,
        c.c_birth_year
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN customer_address sa ON c.c_current_addr_sk = sa.ca_address_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_returns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, c.c_birth_year
),
age_distribution AS (
    SELECT 
        CASE 
            WHEN EXTRACT(YEAR FROM CURRENT_DATE) - c_birth_year < 18 THEN 'Under 18'
            WHEN EXTRACT(YEAR FROM CURRENT_DATE) - c_birth_year BETWEEN 18 AND 25 THEN '18-25'
            WHEN EXTRACT(YEAR FROM CURRENT_DATE) - c_birth_year BETWEEN 26 AND 35 THEN '26-35'
            WHEN EXTRACT(YEAR FROM CURRENT_DATE) - c_birth_year BETWEEN 36 AND 45 THEN '36-45'
            WHEN EXTRACT(YEAR FROM CURRENT_DATE) - c_birth_year BETWEEN 46 AND 55 THEN '46-55'
            WHEN EXTRACT(YEAR FROM CURRENT_DATE) - c_birth_year BETWEEN 56 AND 65 THEN '56-65'
            ELSE '66 and over'
        END AS age_group,
        COUNT(*) AS customer_count
    FROM customer
    GROUP BY age_group
)
SELECT 
    cs.full_name, 
    cs.c_customer_id, 
    cs.cd_gender, 
    cs.cd_marital_status,
    cs.cd_education_status, 
    ad.age_group,
    cs.address_count,
    cs.total_net_profit,
    cs.total_net_loss,
    ad.customer_count AS customers_in_age_group
FROM customer_summary cs
JOIN age_distribution ad ON ad.age_group = CASE 
                                              WHEN EXTRACT(YEAR FROM CURRENT_DATE) - cs.c_birth_year < 18 THEN 'Under 18'
                                              WHEN EXTRACT(YEAR FROM CURRENT_DATE) - cs.c_birth_year BETWEEN 18 AND 25 THEN '18-25'
                                              WHEN EXTRACT(YEAR FROM CURRENT_DATE) - cs.c_birth_year BETWEEN 26 AND 35 THEN '26-35'
                                              WHEN EXTRACT(YEAR FROM CURRENT_DATE) - cs.c_birth_year BETWEEN 36 AND 45 THEN '36-45'
                                              WHEN EXTRACT(YEAR FROM CURRENT_DATE) - cs.c_birth_year BETWEEN 46 AND 55 THEN '46-55'
                                              WHEN EXTRACT(YEAR FROM CURRENT_DATE) - cs.c_birth_year BETWEEN 56 AND 65 THEN '56-65'
                                              ELSE '66 and over'
                                          END
ORDER BY cs.total_net_profit DESC, cs.full_name;
