
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type, ', ', ca.ca_city, ', ', ca.ca_state, ' ', ca.ca_zip) AS full_address,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
ItemSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
),
TopItems AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        is2.total_quantity,
        is2.total_sales
    FROM 
        item i
    JOIN 
        ItemSales is2 ON i.i_item_sk = is2.ws_item_sk
    ORDER BY 
        is2.total_sales DESC
    LIMIT 10
)
SELECT 
    cs.full_name,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.full_address,
    ti.i_item_id,
    ti.i_item_desc,
    ti.total_quantity,
    ti.total_sales
FROM 
    CustomerStats cs
JOIN 
    TopItems ti ON ti.total_quantity > 0
ORDER BY 
    cs.cd_purchase_estimate DESC, ti.total_sales DESC;
