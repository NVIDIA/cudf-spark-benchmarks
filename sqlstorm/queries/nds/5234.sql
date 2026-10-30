
WITH sales_summary AS (
    SELECT 
        w.w_warehouse_id,
        w.w_city,
        i.i_item_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
        AND w.w_state = 'CA'
    GROUP BY 
        w.w_warehouse_id, w.w_city, i.i_item_id
),
demographics_summary AS (
    SELECT 
        cd.cd_marital_status,
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS total_customers,
        SUM(cd.cd_purchase_estimate) AS total_estimated_purchases
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_marital_status, cd.cd_gender
),
final_report AS (
    SELECT 
        ss.w_warehouse_id,
        ss.w_city,
        ss.i_item_id,
        ss.total_quantity,
        ss.total_sales,
        ss.avg_profit,
        ds.cd_marital_status,
        ds.cd_gender,
        ds.total_customers,
        ds.total_estimated_purchases
    FROM 
        sales_summary ss
    LEFT JOIN 
        demographics_summary ds ON ss.total_orders > 100
)
SELECT 
    w.w_warehouse_id,
    w.w_city,
    COUNT(DISTINCT f.i_item_id) AS total_items,
    SUM(f.total_sales) AS aggregate_sales,
    AVG(f.avg_profit) AS average_profit,
    SUM(f.total_customers) AS aggregate_customers
FROM 
    final_report f
JOIN 
    warehouse w ON f.w_warehouse_id = w.w_warehouse_id
GROUP BY 
    w.w_warehouse_id, w.w_city
ORDER BY 
    aggregate_sales DESC
LIMIT 10;
