
WITH sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_sold,
        SUM(ws_net_paid_inc_tax) AS total_revenue,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales 
    WHERE 
        ws_sold_date_sk BETWEEN 1 AND 365
    GROUP BY 
        ws_item_sk
), 
top_sales AS (
    SELECT 
        ss.ws_item_sk,
        ss.total_sold,
        ss.total_revenue,
        ss.order_count,
        i.i_item_desc,
        i.i_category,
        i.i_brand
    FROM 
        sales_summary ss
    JOIN 
        item i ON ss.ws_item_sk = i.i_item_sk
    ORDER BY 
        total_revenue DESC
    LIMIT 10
), 
customer_info AS (
    SELECT 
        DISTINCT c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating
    FROM 
        customer c 
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 2000
), 
purchased_items AS (
    SELECT 
        ws.ws_ship_customer_sk,
        ws.ws_item_sk,
        ws.ws_order_number
    FROM 
        web_sales ws
    JOIN 
        top_sales ts ON ws.ws_item_sk = ts.ws_item_sk
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_credit_rating,
    ts.i_item_desc,
    ts.total_sold,
    ts.total_revenue,
    COUNT(pi.ws_order_number) AS purchase_count
FROM 
    customer_info ci
LEFT JOIN 
    purchased_items pi ON ci.c_customer_sk = pi.ws_ship_customer_sk
JOIN 
    top_sales ts ON pi.ws_item_sk = ts.ws_item_sk
GROUP BY 
    ci.c_first_name, 
    ci.c_last_name, 
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_credit_rating,
    ts.i_item_desc,
    ts.total_sold,
    ts.total_revenue
ORDER BY 
    total_revenue DESC;
