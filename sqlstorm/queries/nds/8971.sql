
WITH sales_summary AS (
    SELECT 
        ws_sold_date_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales,
        AVG(ws_net_paid) AS avg_sales,
        ws_ship_mode_sk,
        ws_web_site_sk
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 
        (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-10-01') AND 
        (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-10-31')
    GROUP BY 
        ws_sold_date_sk, ws_ship_mode_sk, ws_web_site_sk
),
customer_demographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        SUM(CASE WHEN cd_gender = 'M' THEN 1 ELSE 0 END) AS male_customers,
        SUM(CASE WHEN cd_gender = 'F' THEN 1 ELSE 0 END) AS female_customers
    FROM 
        customer_demographics
    JOIN 
        customer ON cd_demo_sk = c_current_cdemo_sk
    GROUP BY 
        cd_demo_sk, cd_gender, cd_marital_status
),
warehouse_shipping AS (
    SELECT
        w_warehouse_sk,
        SUM(ws_ext_ship_cost) AS total_shipping_cost
    FROM
        web_sales
    JOIN
        warehouse ON ws_warehouse_sk = w_warehouse_sk
    GROUP BY
        w_warehouse_sk
)
SELECT 
    d.d_date AS sales_date,
    SUM(s.total_quantity) AS total_quantity_sold,
    SUM(s.total_sales) AS total_sales_amount,
    AVG(s.avg_sales) AS average_sales_per_day,
    c.cd_gender,
    w.total_shipping_cost
FROM 
    sales_summary s
JOIN 
    date_dim d ON s.ws_sold_date_sk = d.d_date_sk
JOIN 
    customer_demographics c ON s.ws_web_site_sk = c.cd_demo_sk
JOIN 
    warehouse_shipping w ON s.ws_ship_mode_sk = w.w_warehouse_sk
GROUP BY 
    d.d_date, c.cd_gender, w.total_shipping_cost
ORDER BY 
    sales_date DESC;
