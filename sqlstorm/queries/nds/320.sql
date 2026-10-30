
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        cd.cd_purchase_estimate,
        cd.cd_dep_count,
        ca.ca_city
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        cd.cd_purchase_estimate > 10000
),
sales_data AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_quantity) AS total_quantity,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
),
top_items AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        sd.total_sales,
        RANK() OVER (ORDER BY sd.total_sales DESC) AS sales_rank
    FROM 
        item i
    JOIN 
        sales_data sd ON i.i_item_sk = sd.ws_item_sk
    WHERE 
        sd.total_sales IS NOT NULL
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.ca_city,
    ti.i_item_id,
    ti.i_item_desc,
    ti.total_sales
FROM 
    customer_info ci
LEFT JOIN 
    top_items ti ON ci.c_customer_sk IN (
        SELECT 
            sr_customer_sk 
        FROM 
            store_returns
        WHERE 
            sr_return_quantity > 0
            AND sr_return_amt_inc_tax > 100
    )
WHERE 
    ti.sales_rank <= 10
ORDER BY 
    ci.ca_city, ti.total_sales DESC;
