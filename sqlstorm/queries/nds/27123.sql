
WITH processed_items AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_product_name,
        LOWER(i.i_item_desc) AS low_item_desc,
        UPPER(i.i_product_name) AS up_product_name,
        LENGTH(i.i_item_desc) AS item_desc_length,
        CONCAT(i.i_product_name, ' - ', i.i_item_desc) AS combined_desc
    FROM 
        item i
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_summary AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
)
SELECT 
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_purchase_estimate,
    ps.combined_desc,
    ps.item_desc_length,
    COALESCE(ss.total_sales, 0) AS total_sales,
    COALESCE(ss.order_count, 0) AS order_count
FROM 
    customer_info ci
JOIN 
    processed_items ps ON ci.c_customer_sk = ps.i_item_sk
LEFT JOIN 
    sales_summary ss ON ci.c_customer_sk = ss.ws_bill_customer_sk
WHERE 
    ps.item_desc_length > 20 AND 
    ci.cd_purchase_estimate > 1000
ORDER BY 
    total_sales DESC, 
    ci.full_name ASC;
