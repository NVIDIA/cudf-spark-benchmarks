
WITH enriched_customer AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        hd.hd_income_band_sk,
        CONCAT(cd.cd_gender, '-', cd.cd_marital_status, '-', cd.cd_education_status) AS demographic_profile
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
sales_summary AS (
    SELECT 
        c.c_customer_sk,
        COUNT(ss.ss_ticket_number) AS total_sales,
        SUM(ss.ss_net_paid) AS total_revenue,
        AVG(ss.ss_net_paid) AS avg_sale_amount
    FROM 
        enriched_customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk
)
SELECT 
    ec.full_name,
    ec.ca_city,
    ec.ca_state,
    ec.ca_country,
    ss.total_sales,
    ss.total_revenue,
    ss.avg_sale_amount,
    CONCAT('Demographics: ', ec.demographic_profile) AS demographic_details
FROM 
    enriched_customer ec
JOIN 
    sales_summary ss ON ec.c_customer_sk = ss.c_customer_sk
WHERE 
    ss.total_sales > 5 
ORDER BY 
    ss.total_revenue DESC;
