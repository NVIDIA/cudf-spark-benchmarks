
WITH ranked_sales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2458487 AND 2458532  
    GROUP BY 
        ws_bill_customer_sk
),
high_spenders AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        rs.total_sales,
        rs.order_count,
        rs.ws_bill_customer_sk
    FROM 
        ranked_sales rs
    JOIN 
        customer c ON rs.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        rs.sales_rank <= 10  
)
SELECT 
    h.c_customer_id,
    h.c_first_name,
    h.c_last_name,
    h.total_sales,
    h.order_count,
    d.d_date AS transaction_date,
    t.t_hour,
    s.s_store_name,
    COUNT(DISTINCT ws.ws_order_number) AS repeat_orders,
    AVG(ws.ws_net_profit) AS avg_net_profit
FROM 
    high_spenders h
JOIN 
    web_sales ws ON h.ws_bill_customer_sk = ws.ws_bill_customer_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN 
    time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
JOIN 
    store s ON ws.ws_ship_addr_sk = s.s_store_sk
WHERE 
    d.d_year = 2001 
GROUP BY 
    h.c_customer_id, h.c_first_name, h.c_last_name, h.total_sales, h.order_count, d.d_date, t.t_hour, s.s_store_name
ORDER BY 
    h.total_sales DESC;
