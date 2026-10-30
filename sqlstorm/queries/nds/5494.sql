
WITH customer_data AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
sales_data AS (
    SELECT 
        w.w_warehouse_name,
        CAST(d.d_date AS DATE) AS sale_date,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales_by_date
    FROM web_sales ws
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY w.w_warehouse_name, d.d_date
),
combined_data AS (
    SELECT 
        cd.c_customer_id,
        cd.c_first_name,
        cd.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        sd.w_warehouse_name,
        sd.sale_date,
        sd.total_sales_by_date,
        COALESCE(cd.total_sales, 0) AS total_sales,
        COALESCE(cd.order_count, 0) AS order_count
    FROM customer_data cd
    FULL OUTER JOIN sales_data sd ON cd.c_customer_id IS NULL OR sd.sale_date IS NULL
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    c.cd_gender,
    s.w_warehouse_name,
    s.sale_date,
    SUM(s.total_sales_by_date) AS total_sales,
    SUM(c.total_sales) AS customer_total_sales,
    SUM(c.order_count) AS total_orders
FROM combined_data s
LEFT JOIN customer_data c ON c.c_customer_id = s.c_customer_id
GROUP BY c.c_first_name, c.c_last_name, c.cd_gender, s.w_warehouse_name, s.sale_date
ORDER BY total_sales DESC, customer_total_sales DESC;
