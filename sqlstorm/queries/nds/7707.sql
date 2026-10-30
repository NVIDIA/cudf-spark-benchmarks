
WITH sales_summary AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        SUM(ws.ws_ext_tax) AS total_tax
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN 
        item it ON ws.ws_item_sk = it.i_item_sk
    WHERE 
        dd.d_year = 2023
        AND it.i_current_price > 10.00
    GROUP BY 
        ws.ws_sold_date_sk,
        ws.ws_item_sk
), customer_summary AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ss.total_sales) AS total_spent,
        SUM(ss.total_discount) AS total_discount,
        SUM(ss.total_tax) AS total_tax
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    JOIN 
        sales_summary ss ON ws.ws_sold_date_sk = ss.ws_sold_date_sk AND ws.ws_item_sk = ss.ws_item_sk
    GROUP BY 
        c.c_customer_sk
), gender_summary AS (
    SELECT 
        cd.cd_gender,
        COUNT(DISTINCT cs.c_customer_sk) AS customer_count,
        SUM(cs.total_orders) AS total_orders,
        SUM(cs.total_spent) AS total_spent,
        SUM(cs.total_discount) AS total_discount,
        SUM(cs.total_tax) AS total_tax
    FROM 
        customer_summary cs
    JOIN 
        customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender
)
SELECT 
    gs.cd_gender,
    gs.customer_count,
    gs.total_orders,
    gs.total_spent,
    gs.total_discount,
    gs.total_tax,
    (gs.total_spent / NULLIF(gs.customer_count, 0) ) AS avg_spent_per_customer
FROM 
    gender_summary gs
ORDER BY 
    total_spent DESC;
