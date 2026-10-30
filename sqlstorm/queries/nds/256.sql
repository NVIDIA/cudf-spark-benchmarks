
WITH sales_data AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_net_paid) AS total_sales_amount,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
top_items AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity_sold,
        sd.total_sales_amount,
        ROW_NUMBER() OVER (ORDER BY sd.total_quantity_sold DESC) AS sales_rank
    FROM 
        sales_data sd
),
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        d.d_year,
        SUM(CASE WHEN w.sm_ship_mode_sk IS NULL THEN 0 ELSE ws.ws_quantity END) AS total_web_sales,
        MAX(cd.cd_gender) AS gender,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COALESCE(SUM(st.ss_quantity), 0) AS in_store_sales
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        store_sales st ON c.c_customer_sk = st.ss_customer_sk
    LEFT JOIN 
        ship_mode w ON ws.ws_ship_mode_sk = w.sm_ship_mode_sk
    JOIN 
        date_dim d ON d.d_date_sk = ws.ws_sold_date_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_sk, d.d_year
)
SELECT 
    cs.c_customer_sk,
    cs.total_web_sales,
    cs.total_orders,
    cs.gender,
    cs.in_store_sales,
    ti.total_quantity_sold,
    ti.total_sales_amount,
    COALESCE(cd.cd_marital_status, 'Unknown') AS marital_status
FROM 
    customer_summary cs
LEFT JOIN 
    top_items ti ON cs.total_web_sales > 100 AND ti.sales_rank IS NOT NULL
LEFT JOIN 
    customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
WHERE 
    cs.total_orders > 2 AND
    (cs.gender = 'M' OR cs.gender = 'F')
ORDER BY 
    cs.total_web_sales DESC, 
    cs.total_orders DESC
LIMIT 100;
