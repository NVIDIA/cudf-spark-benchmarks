
WITH sales_data AS (
    SELECT 
        w.w_warehouse_id,
        i.i_item_id,
        SUM(ws.ws_quantity) AS total_sales_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales_amount,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
        AND cd.cd_gender = 'F'
        AND cd.cd_marital_status = 'M'
    GROUP BY 
        w.w_warehouse_id, i.i_item_id
),
ranked_sales AS (
    SELECT 
        w_warehouse_id, 
        i_item_id, 
        total_sales_quantity, 
        total_sales_amount, 
        avg_sales_price, 
        total_orders,
        ROW_NUMBER() OVER (PARTITION BY w_warehouse_id ORDER BY total_sales_amount DESC) AS rank
    FROM 
        sales_data
)

SELECT 
    w_warehouse_id AS warehouse_id, 
    i_item_id, 
    total_sales_quantity, 
    total_sales_amount, 
    avg_sales_price, 
    total_orders
FROM 
    ranked_sales 
WHERE 
    rank <= 5
ORDER BY 
    warehouse_id, 
    total_sales_amount DESC;
