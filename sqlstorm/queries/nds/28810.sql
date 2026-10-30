WITH customer_data AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        cd.cd_marital_status,
        cd.cd_gender,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
        JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
        JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'F' AND
        cd.cd_marital_status = 'M' AND
        cd.cd_purchase_estimate > 500
),
top_items AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        COUNT(ws.ws_order_number) AS sales_count
    FROM 
        item i
        JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    WHERE 
        ws.ws_ship_date_sk >= 20220101 
    GROUP BY 
        i.i_item_id, i.i_item_desc
    ORDER BY 
        sales_count DESC
    LIMIT 10
),
final_output AS (
    SELECT 
        cd.c_customer_id,
        cd.c_first_name,
        cd.c_last_name,
        cd.ca_city,
        cd.ca_state,
        ti.i_item_desc,
        ti.sales_count
    FROM 
        customer_data cd
        JOIN top_items ti ON cd.cd_purchase_estimate BETWEEN 501 AND 1000
)

SELECT 
    CONCAT(c_first_name, ' ', c_last_name) AS full_name,
    ca_city,
    ca_state,
    i_item_desc,
    sales_count
FROM 
    final_output
ORDER BY 
    sales_count DESC;