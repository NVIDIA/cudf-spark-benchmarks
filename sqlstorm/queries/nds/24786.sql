
WITH customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COALESCE(NULLIF(cd.cd_credit_rating, 'Low'), 'Average') AS credit_rating,
        COUNT(DISTINCT cr.cr_order_number) AS returns_count,
        SUM(CASE WHEN cr.cr_return_quantity > 0 THEN cr.cr_return_amount ELSE 0 END) AS total_return_amount,
        SUM(ws.ws_quantity) AS total_sales_quantity,
        SUM(ws.ws_net_paid_inc_tax) AS total_net_paid,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS gender_rank
    FROM 
        customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN catalog_returns cr ON cr.cr_returning_customer_sk = c.c_customer_sk
    WHERE 
        cd.cd_marital_status IN ('M', 'S')
        AND (cd.cd_purchase_estimate IS NOT NULL OR cr.cr_return_quantity IS NOT NULL)
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate, cd.cd_credit_rating
),
address_details AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_city ORDER BY ca.ca_address_sk) AS city_rank
    FROM 
        customer_address ca
    WHERE 
        ca.ca_country = 'USA'
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cs.credit_rating,
    COUNT(DISTINCT ad.ca_address_sk) AS distinct_addresses,
    AVG(cs.total_sales_quantity) AS avg_sales_quantity,
    SUM(CASE WHEN cs.gender_rank = 1 THEN cs.total_net_paid ELSE 0 END) AS top_gender_sales,
    SUM(CASE WHEN ad.city_rank <= 5 THEN cs.total_net_paid ELSE 0 END) AS top_city_sales,
    SUM(cs.total_net_paid) AS total_net_paid
FROM 
    customer_summary cs
LEFT JOIN address_details ad ON ad.ca_address_sk = cs.c_customer_sk 
GROUP BY 
    cs.c_first_name,
    cs.c_last_name,
    cs.credit_rating
HAVING 
    SUM(cs.total_net_paid) > (SELECT AVG(total_net_paid) FROM customer_summary)
ORDER BY 
    total_net_paid DESC
LIMIT 10 OFFSET 10;
