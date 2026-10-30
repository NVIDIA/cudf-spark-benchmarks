
WITH sales_summary AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity_sold, 
        SUM(ws_net_paid) AS total_net_paid,
        SUM(ws_ext_discount_amt) AS total_discount,
        SUM(ws_ext_tax) AS total_tax,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_quantity) DESC) AS rank
    FROM 
        web_sales 
    GROUP BY 
        ws_item_sk
),
top_customers AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_net_paid) AS total_spent
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
    HAVING 
        SUM(ws_net_paid) > 1000
),
item_details AS (
    SELECT 
        i_item_sk,
        i_item_desc,
        i_current_price,
        i_brand
    FROM 
        item
)
SELECT 
    id.i_item_desc,
    id.i_brand,
    ss.total_quantity_sold,
    ss.total_net_paid,
    tc.total_orders,
    tc.total_spent
FROM 
    sales_summary ss
JOIN 
    item_details id ON ss.ws_item_sk = id.i_item_sk
LEFT JOIN 
    top_customers tc ON ss.ws_item_sk = tc.ws_bill_customer_sk
WHERE 
    ss.rank <= 5
    AND ss.total_net_paid IS NOT NULL
ORDER BY 
    ss.total_quantity_sold DESC, 
    tc.total_spent DESC NULLS LAST;
