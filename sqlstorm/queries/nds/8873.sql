
WITH sales_stats AS (
    SELECT 
        d.d_year,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        SUM(ws.ws_quantity) AS total_quantity
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_ship_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'F' 
        AND d.d_year BETWEEN 2020 AND 2023
    GROUP BY 
        d.d_year
), 
top_items AS (
    SELECT 
        i.i_item_id,
        i.i_product_name,
        SUM(ws.ws_quantity) AS total_quantity_sold
    FROM 
        item i
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_id, i.i_product_name
    ORDER BY 
        total_quantity_sold DESC
    LIMIT 10
)
SELECT 
    ss.d_year, 
    ss.total_net_profit, 
    ss.total_orders, 
    ss.avg_sales_price, 
    ss.total_quantity,
    ti.i_product_name,
    ti.total_quantity_sold
FROM 
    sales_stats ss
JOIN 
    top_items ti ON ss.d_year = (SELECT MAX(d.d_year) FROM date_dim d WHERE d.d_year BETWEEN 2020 AND 2023)
ORDER BY 
    ss.d_year, ti.total_quantity_sold DESC;
