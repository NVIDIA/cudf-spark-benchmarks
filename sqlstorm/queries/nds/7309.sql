
WITH sales_summary AS (
    SELECT 
        w.w_warehouse_id,
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_item_sk) AS unique_items_sold
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
        AND d.d_month_seq BETWEEN 1 AND 6
    GROUP BY 
        w.w_warehouse_id, c.c_customer_id
),
top_customers AS (
    SELECT 
        c_customer_id,
        total_sales,
        total_orders,
        unique_items_sold,
        ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        sales_summary
)
SELECT 
    tc.c_customer_id,
    tc.total_sales,
    tc.total_orders,
    tc.unique_items_sold,
    ca.ca_city,
    ca.ca_state,
    cd.cd_gender,
    cd.cd_marital_status
FROM 
    top_customers tc
JOIN 
    customer c ON tc.c_customer_id = c.c_customer_id
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE 
    tc.sales_rank <= 10
ORDER BY 
    tc.total_sales DESC;
