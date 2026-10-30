
WITH sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        SUM(ws_ext_discount_amt) AS total_discount,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2459580 AND 2459650 
    GROUP BY 
        ws_item_sk
),
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws.ws_order_number) AS orders_count,
        SUM(ws.ws_sales_price) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
),
warehouse_summary AS (
    SELECT 
        w.w_warehouse_sk,
        SUM(i.inv_quantity_on_hand) AS total_inventory
    FROM 
        warehouse w
    JOIN 
        inventory i ON w.w_warehouse_sk = i.inv_warehouse_sk
    GROUP BY 
        w.w_warehouse_sk
)
SELECT 
    cs.c_customer_sk,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.orders_count,
    cs.total_spent,
    ss.total_quantity,
    ss.total_sales,
    ss.total_discount,
    ws.w_warehouse_sk,
    ws.total_inventory
FROM 
    customer_summary cs
JOIN 
    sales_summary ss ON cs.orders_count > 5
JOIN 
    warehouse_summary ws ON ss.total_sales > 1000
WHERE 
    cs.total_spent > 500
ORDER BY 
    cs.total_spent DESC, ss.total_sales DESC
LIMIT 100;
