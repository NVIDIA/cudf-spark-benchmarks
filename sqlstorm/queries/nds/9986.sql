
WITH sales_summary AS (
    SELECT 
        d.d_year AS sales_year,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid_inc_tax) AS total_revenue,
        AVG(ws.ws_quantity) AS average_quantity
    FROM 
        web_sales AS ws
    JOIN 
        date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        item AS i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        customer AS c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        d.d_year BETWEEN 1998 AND 2001 
        AND cd.cd_gender = 'F' 
        AND cd.cd_marital_status = 'M'
    GROUP BY 
        d.d_year
), 
warehouse_summary AS (
    SELECT 
        w.w_warehouse_id,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory AS inv
    JOIN 
        warehouse AS w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
)
SELECT 
    ss.sales_year,
    ss.total_orders,
    ss.total_revenue,
    ss.average_quantity,
    ws.w_warehouse_id,
    ws.total_inventory
FROM 
    sales_summary AS ss
JOIN 
    warehouse_summary AS ws ON ss.sales_year = EXTRACT(YEAR FROM DATE '2002-10-01')
ORDER BY 
    ss.sales_year, ws.total_inventory DESC;
