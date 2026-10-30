
WITH customer_data AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS purchase_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        cd.cd_gender = 'F' 
        AND cd.cd_marital_status = 'M' 
        AND ca.ca_state = 'CA'
    GROUP BY 
        c.c_customer_id, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status, 
        c.c_first_name, 
        c.c_last_name, 
        ca.ca_city, 
        ca.ca_state
),
promotion_summary AS (
    SELECT 
        p.p_promo_name,
        SUM(cs.cs_net_profit) AS total_promo_profit
    FROM 
        promotion p
    JOIN 
        catalog_sales cs ON p.p_promo_sk = cs.cs_promo_sk
    GROUP BY 
        p.p_promo_name
),
final_summary AS (
    SELECT 
        cd.c_customer_id,
        cd.c_first_name,
        cd.c_last_name,
        cd.ca_city,
        cd.ca_state,
        cd.total_net_profit,
        ps.p_promo_name AS promo_name,
        ps.total_promo_profit
    FROM 
        customer_data cd
    LEFT JOIN 
        promotion_summary ps ON cd.total_net_profit > 1000
)
SELECT 
    f.c_customer_id,
    f.c_first_name,
    f.c_last_name,
    f.ca_city,
    f.ca_state,
    f.total_net_profit,
    f.promo_name,
    f.total_promo_profit
FROM 
    final_summary f
ORDER BY 
    f.total_net_profit DESC, 
    f.c_last_name ASC
LIMIT 100;
