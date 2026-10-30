
WITH sales_summary AS (
    SELECT 
        d.d_year,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        COUNT(DISTINCT ws_bill_customer_sk) AS unique_customers,
        SUM(ws_net_profit) AS total_net_profit
    FROM 
        web_sales
    JOIN 
        date_dim d ON ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year
),
customer_demographics AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        SUM(CASE WHEN cd_gender = 'F' THEN 1 ELSE 0 END) AS female_customers,
        SUM(CASE WHEN cd_gender = 'M' THEN 1 ELSE 0 END) AS male_customers
    FROM 
        customer 
    JOIN 
        customer_demographics cd ON c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd_gender, cd_marital_status
),
warehouse_summary AS (
    SELECT 
        w.w_warehouse_id,
        COUNT(DISTINCT ws_order_number) AS orders_in_warehouse,
        SUM(ws_ext_sales_price) AS warehouse_sales
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
)
SELECT 
    ss.d_year,
    ss.total_sales,
    ss.total_orders,
    ss.unique_customers,
    ss.total_net_profit,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.customer_count,
    cd.female_customers,
    cd.male_customers,
    ws.w_warehouse_id,
    ws.orders_in_warehouse,
    ws.warehouse_sales
FROM 
    sales_summary ss
JOIN 
    customer_demographics cd ON cd.customer_count > 0
JOIN 
    warehouse_summary ws ON ws.orders_in_warehouse > 0
ORDER BY 
    ss.d_year DESC, 
    ws.w_warehouse_id;
