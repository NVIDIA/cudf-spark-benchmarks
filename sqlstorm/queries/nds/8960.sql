
WITH sales_summary AS (
    SELECT 
        d.d_year AS sales_year,
        d.d_month_seq AS sales_month,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        d.d_year = 2023 AND 
        (cd.cd_gender = 'F' OR cd.cd_gender = 'M')
    GROUP BY 
        d.d_year, d.d_month_seq
), warehouse_summary AS (
    SELECT 
        w.w_warehouse_id,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM 
        warehouse w
    JOIN 
        inventory inv ON w.w_warehouse_sk = inv.inv_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
)
SELECT 
    ss.sales_year,
    ss.sales_month,
    ss.total_sales,
    ss.total_discount,
    ss.total_orders,
    ws.total_inventory
FROM 
    sales_summary ss
JOIN 
    warehouse_summary ws ON ss.sales_year = 2023
ORDER BY 
    ss.sales_month;
