
WITH ranked_sales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        RANK() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_quantity DESC) AS quantity_rank,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_net_paid DESC) AS payment_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year >= 1980
),
avg_sales AS (
    SELECT 
        ws_item_sk,
        AVG(ws_quantity) AS avg_quantity,
        SUM(ws_net_paid) AS total_net_paid
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
complete_info AS (
    SELECT 
        rs.ws_order_number,
        i.i_item_desc,
        rs.ws_quantity,
        rs.ws_sales_price,
        ASG.avg_quantity,
        ASG.total_net_paid
    FROM 
        ranked_sales rs
    JOIN 
        item i ON rs.ws_item_sk = i.i_item_sk
    LEFT JOIN 
        avg_sales ASG ON rs.ws_item_sk = ASG.ws_item_sk
    WHERE 
        rs.quantity_rank = 1 AND rs.payment_rank = 1
)
SELECT 
    ci.ws_order_number,
    ci.i_item_desc,
    ci.ws_quantity,
    ci.ws_sales_price,
    COALESCE(ci.avg_quantity, 0) AS avg_quantity,
    ci.total_net_paid,
    CASE 
        WHEN ci.total_net_paid > 1000 THEN 'High Value'
        WHEN ci.total_net_paid BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS order_value_category
FROM 
    complete_info ci
ORDER BY 
    ci.total_net_paid DESC
LIMIT 100;
