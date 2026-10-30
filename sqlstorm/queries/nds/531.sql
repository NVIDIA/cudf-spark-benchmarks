
WITH sales_summary AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_ext_tax,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS rnk
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2022 AND 
        dd.d_month_seq BETWEEN 1 AND 6
),
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_ext_sales_price) AS avg_order_value
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
),
item_summary AS (
    SELECT 
        i.i_item_sk,
        i.i_product_name,
        SUM(ws.ws_quantity) AS total_sold,
        AVG(ws.ws_sales_price) AS avg_price
    FROM 
        item i
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_sk, i.i_product_name
)
SELECT 
    cs.c_customer_sk,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.total_orders,
    cs.total_quantity,
    cs.total_sales,
    cs.avg_order_value,
    ss.ws_item_sk,
    ss.ws_sales_price,
    ss.ws_quantity,
    ss.ws_ext_sales_price
FROM 
    customer_summary cs
JOIN 
    sales_summary ss ON cs.c_customer_sk = ss.ws_order_number
WHERE 
    ss.rnk <= 5
UNION ALL
SELECT 
    cs.c_customer_sk,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.total_orders,
    cs.total_quantity,
    cs.total_sales,
    cs.avg_order_value,
    NULL AS ws_item_sk,
    NULL AS ws_sales_price,
    NULL AS ws_quantity,
    NULL AS ws_ext_sales_price
FROM 
    customer_summary cs
WHERE 
    cs.total_orders = 0
ORDER BY 
    c_customer_sk, total_sales DESC;
