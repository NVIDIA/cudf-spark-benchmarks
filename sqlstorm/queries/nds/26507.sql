
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
popular_items AS (
    SELECT 
        i.i_item_sk,
        i.i_product_name,
        SUM(ss.ss_quantity) AS total_sold
    FROM 
        store_sales ss
    JOIN 
        item i ON ss.ss_item_sk = i.i_item_sk
    GROUP BY 
        i.i_item_sk, i.i_product_name
    ORDER BY 
        total_sold DESC
    LIMIT 10
)
SELECT 
    ci.full_name,
    ci.ca_city,
    ci.ca_state,
    pi.i_product_name,
    pi.total_sold
FROM 
    customer_info ci
JOIN 
    store_sales ss ON ci.c_customer_sk = ss.ss_customer_sk
JOIN 
    popular_items pi ON ss.ss_item_sk = pi.i_item_sk
WHERE 
    ci.cd_gender = 'F' 
    AND ci.cd_marital_status = 'M'
ORDER BY 
    ci.ca_city, pi.total_sold DESC;
