
WITH sales_data AS (
    SELECT 
        ws.ws_item_sk AS item_id,
        SUM(ws.ws_quantity) AS total_sales_quantity,
        SUM(ws.ws_sales_price) AS total_sales_amount,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        d.d_year = 2023
        AND c.c_birth_year < 1970
    GROUP BY 
        ws.ws_item_sk
),
top_items AS (
    SELECT 
        item_id,
        total_sales_quantity,
        total_sales_amount,
        total_orders,
        avg_net_profit,
        ROW_NUMBER() OVER (ORDER BY total_sales_amount DESC) AS sales_rank
    FROM 
        sales_data
)
SELECT 
    ti.item_id,
    ti.total_sales_quantity,
    ti.total_sales_amount,
    ti.total_orders,
    ti.avg_net_profit,
    i.i_item_desc,
    i.i_category,
    w.w_warehouse_name
FROM 
    top_items ti
JOIN 
    item i ON ti.item_id = i.i_item_sk
JOIN 
    inventory inv ON inv.inv_item_sk = ti.item_id
JOIN 
    warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
WHERE 
    ti.sales_rank <= 10
ORDER BY 
    ti.total_sales_amount DESC;
