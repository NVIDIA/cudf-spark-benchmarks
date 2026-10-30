
WITH sales_data AS (
    SELECT 
        w.w_warehouse_name,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales_amount,
        AVG(ws.ws_net_profit) AS avg_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023 AND 
        cd.cd_gender = 'F' AND 
        i.i_current_price > 50.00
    GROUP BY 
        w.w_warehouse_name
),
warehouse_summary AS (
    SELECT 
        w.w_warehouse_name,
        COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        warehouse w
    JOIN 
        sales_data sd ON w.w_warehouse_name = sd.w_warehouse_name
    JOIN 
        web_sales ws ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        w.w_warehouse_name
)
SELECT 
    sd.w_warehouse_name,
    total_quantity,
    total_sales_amount,
    avg_net_profit,
    unique_customers,
    avg_purchase_estimate
FROM 
    sales_data sd
JOIN 
    warehouse_summary ws ON sd.w_warehouse_name = ws.w_warehouse_name
ORDER BY 
    total_sales_amount DESC, unique_customers DESC;
