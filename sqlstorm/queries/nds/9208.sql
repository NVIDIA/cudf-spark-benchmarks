
WITH ranked_sales AS (
    SELECT 
        s_store_name,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders,
        DENSE_RANK() OVER (PARTITION BY s_store_name ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        store s
    JOIN 
        web_sales ws ON s.s_store_sk = ws.ws_warehouse_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        s_store_name
),
top_stores AS (
    SELECT 
        s_store_name,
        total_sales,
        total_orders
    FROM 
        ranked_sales
    WHERE 
        sales_rank <= 10
)
SELECT 
    ts.s_store_name,
    ts.total_sales,
    ts.total_orders,
    cd.cd_gender,
    cd.cd_marital_status,
    ad.ca_state,
    (SELECT COUNT(*) 
     FROM customer c 
     WHERE c.c_current_addr_sk = ad.ca_address_sk AND c.c_preferred_cust_flag = 'Y') AS preferred_customer_count
FROM 
    top_stores ts
JOIN 
    store s ON ts.s_store_name = s.s_store_name
JOIN 
    customer_address ad ON s.s_store_sk = ad.ca_address_sk
JOIN 
    customer_demographics cd ON cd.cd_demo_sk = s.s_store_sk
ORDER BY 
    ts.total_sales DESC, ts.total_orders DESC;
