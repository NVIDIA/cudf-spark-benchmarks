
WITH sales_summary AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales AS ws
    JOIN 
        warehouse AS w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2001
        AND d.d_moy IN (5, 6) 
    GROUP BY 
        w.w_warehouse_id
),
customer_summary AS (
    SELECT 
        ca.ca_city,
        COUNT(DISTINCT c.c_customer_id) AS customer_count,
        AVG(cd.cd_dep_count) AS avg_dependent_count
    FROM 
        customer_address AS ca
    JOIN 
        customer AS c ON ca.ca_address_sk = c.c_current_addr_sk
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        ca.ca_city
),
top_sales_warehouses AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ss.total_quantity) AS total_quantity,
        SUM(ss.total_profit) AS total_profit,
        RANK() OVER (ORDER BY SUM(ss.total_profit) DESC) AS sales_rank
    FROM 
        sales_summary AS ss
    JOIN 
        warehouse AS w ON ss.w_warehouse_id = w.w_warehouse_id
    GROUP BY 
        w.w_warehouse_id
)

SELECT 
    t.w_warehouse_id AS warehouse_id,
    t.total_quantity,
    t.total_profit,
    c.ca_city,
    c.customer_count,
    c.avg_dependent_count,
    t.sales_rank
FROM 
    top_sales_warehouses AS t
JOIN 
    customer_summary AS c ON c.customer_count > 100
WHERE 
    t.sales_rank <= 10
ORDER BY 
    t.total_profit DESC;
