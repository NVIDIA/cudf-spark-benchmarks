
WITH sales_data AS (
    SELECT 
        ws.ws_sales_price,
        ws.ws_quantity,
        c.c_customer_id AS customer_id,
        c.c_first_name,
        c.c_last_name,
        d.d_year AS year,
        d.d_month_seq AS month_seq,
        w.w_warehouse_name AS warehouse_name,
        sm.sm_type AS sm_type,
        cd.cd_gender AS gender,
        ph.discounted_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY ws.ws_sold_date_sk DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN (
        SELECT 
            ws_item_sk,
            SUM(ws_sales_price * ws_quantity) * 0.9 AS discounted_sales
        FROM 
            web_sales
        GROUP BY 
            ws_item_sk
    ) ph ON ws.ws_item_sk = ph.ws_item_sk
)
SELECT 
    customer_id,
    c_first_name,
    c_last_name,
    SUM(ws_sales_price * ws_quantity) AS total_sales,
    COUNT(*) AS order_count,
    MAX(year) AS max_year,
    MAX(month_seq) AS max_month_seq,
    MAX(warehouse_name) AS preferred_warehouse,
    MAX(sm_type) AS preferred_shipping_method,
    MAX(gender) AS gender,
    MAX(discounted_sales) AS total_discounted_sales
FROM 
    sales_data
WHERE 
    rank = 1
GROUP BY 
    customer_id,
    c_first_name,
    c_last_name
ORDER BY 
    total_sales DESC
LIMIT 100;
