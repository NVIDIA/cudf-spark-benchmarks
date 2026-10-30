
WITH sales_summary AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2022
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk
),
top_items AS (
    SELECT 
        ss.ws_item_sk,
        ss.total_quantity,
        ss.total_sales,
        RANK() OVER (ORDER BY ss.total_sales DESC) AS sales_rank
    FROM 
        sales_summary ss
    WHERE 
        ss.total_sales > 1000
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
item_info AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price
    FROM 
        item i
)
SELECT 
    ci.c_customer_sk,
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ii.i_item_desc,
    ii.i_current_price,
    ti.total_quantity,
    ti.total_sales
FROM 
    top_items ti
JOIN 
    item_info ii ON ti.ws_item_sk = ii.i_item_sk
JOIN 
    web_sales ws ON ti.ws_item_sk = ws.ws_item_sk
LEFT JOIN 
    customer_info ci ON ws.ws_bill_customer_sk = ci.c_customer_sk
WHERE 
    ii.i_current_price < (SELECT AVG(i_current_price) FROM item)
ORDER BY 
    ti.total_sales DESC, ci.c_last_name ASC
LIMIT 50;
