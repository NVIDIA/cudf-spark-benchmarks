
WITH customer_data AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        CASE 
            WHEN cd.cd_gender = 'M' THEN CONCAT('Mr. ', c.c_first_name)
            WHEN cd.cd_gender = 'F' THEN CONCAT('Ms. ', c.c_first_name)
            ELSE c.c_first_name
        END AS salutation,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type, ', ', ca.ca_city, ', ', ca.ca_state, ' ', ca.ca_zip) AS address,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
item_stats AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        SUM(ws.ws_quantity) AS total_sold,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        item i
    JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_sk, i.i_item_desc
),
ranked_sales AS (
    SELECT 
        id.*,
        RANK() OVER (ORDER BY id.total_sold DESC) AS sales_rank
    FROM 
        item_stats id
),
top_items AS (
    SELECT 
        r.i_item_sk AS item_sk,
        r.i_item_desc AS item_desc,
        r.total_sold,
        r.avg_sales_price,
        r.order_count
    FROM 
        ranked_sales r
    WHERE 
        r.sales_rank <= 10
)
SELECT 
    cd.full_name,
    cd.salutation,
    cd.address,
    ti.item_desc,
    ti.total_sold,
    ti.avg_sales_price
FROM 
    customer_data cd
JOIN web_sales ws ON cd.c_customer_sk = ws.ws_bill_customer_sk
JOIN top_items ti ON ws.ws_item_sk = ti.item_sk
ORDER BY 
    cd.full_name, ti.total_sold DESC;
