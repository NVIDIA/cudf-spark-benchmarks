
WITH customer_full_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
item_statistics AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        COUNT(ws.ws_order_number) AS total_sales,
        SUM(ws.ws_sales_price) AS total_revenue,
        AVG(ws.ws_sales_price) AS average_price
    FROM 
        item i 
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_sk, i.i_item_desc
),
customer_engagement AS (
    SELECT 
        cfi.c_customer_sk,
        COUNT(DISTINCT w.web_site_id) AS total_web_visits,
        AVG(wp.wp_char_count) AS avg_page_characters
    FROM 
        customer_full_info cfi
    LEFT JOIN 
        web_page wp ON cfi.c_customer_sk = wp.wp_customer_sk
    LEFT JOIN 
        web_site w ON wp.wp_web_page_sk = w.web_site_sk
    GROUP BY 
        cfi.c_customer_sk
)
SELECT 
    cfi.c_customer_sk,
    cfi.c_first_name,
    cfi.c_last_name,
    cfi.ca_city,
    cfi.ca_state,
    cfo.total_sales,
    cfo.total_revenue,
    cfo.average_price,
    ce.total_web_visits,
    ce.avg_page_characters
FROM 
    customer_full_info cfi
JOIN 
    item_statistics cfo ON cfi.c_customer_sk = cfo.i_item_sk
JOIN 
    customer_engagement ce ON cfi.c_customer_sk = ce.c_customer_sk
WHERE 
    cfi.cd_gender = 'F' AND 
    cfi.cd_education_status LIKE '%Bachelor%' 
ORDER BY 
    cfi.c_last_name ASC, cfi.c_first_name ASC;
