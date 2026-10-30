
WITH sales_data AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        inv.inv_quantity_on_hand,
        w.w_warehouse_id,
        d.d_year,
        d.d_month_seq
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        inventory inv ON ws.ws_item_sk = inv.inv_item_sk AND ws.ws_warehouse_sk = inv.inv_warehouse_sk
    JOIN 
        warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 1000 AND 2000
        AND cd.cd_gender = 'F'
        AND cd.cd_marital_status = 'M'
        AND w.w_warehouse_id LIKE 'W%'
),
aggregated_sales AS (
    SELECT 
        d_month_seq,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        AVG(inv_quantity_on_hand) AS avg_inventory
    FROM 
        sales_data
    GROUP BY 
        d_month_seq
)
SELECT 
    total_quantity,
    total_net_profit,
    avg_inventory,
    CASE 
        WHEN total_net_profit > 10000 THEN 'High Profit'
        WHEN total_net_profit BETWEEN 5000 AND 10000 THEN 'Moderate Profit'
        ELSE 'Low Profit'
    END AS profit_category
FROM 
    aggregated_sales
ORDER BY 
    d_month_seq;
