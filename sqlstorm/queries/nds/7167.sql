
WITH sales_summary AS (
    SELECT 
        w.w_warehouse_id AS warehouse_id,
        i.i_item_id AS item_id,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_paid) AS total_net_sales,
        AVG(ws.ws_net_profit) AS average_net_profit
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2451545 AND 2451877 
    GROUP BY 
        w.w_warehouse_id, i.i_item_id
),
demographics_summary AS (
    SELECT 
        cd.cd_gender AS customer_gender,
        COUNT(DISTINCT c.c_customer_id) AS unique_customers,
        AVG(cd.cd_purchase_estimate) AS average_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender
)
SELECT 
    ss.warehouse_id,
    ss.item_id,
    ss.total_quantity_sold,
    ss.total_net_sales,
    ss.average_net_profit,
    ds.customer_gender,
    ds.unique_customers,
    ds.average_purchase_estimate
FROM 
    sales_summary ss
JOIN 
    demographics_summary ds ON ss.total_net_sales > 5000 
ORDER BY 
    ss.total_net_sales DESC, ds.unique_customers DESC
LIMIT 100;
