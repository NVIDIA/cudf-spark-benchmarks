
WITH customer_summary AS (
    SELECT 
        c.c_customer_id,
        ca.ca_city,
        cd.cd_gender,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price) AS total_spent,
        AVG(ws.ws_sales_price) AS average_order_value
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cd.cd_marital_status = 'M'
        AND cd.cd_purchase_estimate > 500
    GROUP BY 
        c.c_customer_id, ca.ca_city, cd.cd_gender
),
top_customers AS (
    SELECT 
        c.c_customer_id,
        cs.total_orders,
        cs.total_spent
    FROM 
        customer_summary AS cs
    JOIN 
        customer AS c ON cs.c_customer_id = c.c_customer_id
    WHERE 
        cs.total_orders > 5
    ORDER BY 
        cs.total_spent DESC
    LIMIT 10
),
sales_analysis AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ws.ws_ext_sales_price) AS warehouse_sales
    FROM 
        web_sales AS ws
    JOIN 
        warehouse AS w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) - 30 FROM date_dim AS d)
    GROUP BY 
        w.w_warehouse_id
)
SELECT 
    tc.c_customer_id,
    tc.total_orders,
    tc.total_spent,
    sa.w_warehouse_id,
    sa.warehouse_sales
FROM 
    top_customers AS tc
JOIN 
    sales_analysis AS sa ON tc.total_orders = (SELECT MAX(total_orders) FROM top_customers)
ORDER BY 
    tc.total_spent DESC;
