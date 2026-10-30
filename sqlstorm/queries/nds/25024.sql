
WITH customer_data AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        cd.cd_purchase_estimate,
        REPLACE(c.c_email_address, '@domain.com', '') AS email_username
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
item_summary AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        SUM(ws.ws_quantity) AS total_sales_quantity,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM 
        item i
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_id,
        i.i_item_desc
),
top_items AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        total_sales_quantity,
        avg_sales_price,
        RANK() OVER (ORDER BY total_sales_quantity DESC) AS item_rank
    FROM 
        item_summary i
)
SELECT 
    cd.full_name,
    cd.ca_city,
    cd.ca_state,
    ti.i_item_desc,
    ti.total_sales_quantity,
    ti.avg_sales_price
FROM 
    customer_data cd
JOIN 
    top_items ti ON ti.item_rank <= 10
WHERE 
    cd.cd_gender = 'F' 
    AND cd.cd_marital_status = 'M'
ORDER BY 
    ti.total_sales_quantity DESC;
