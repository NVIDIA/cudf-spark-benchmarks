
WITH  purchase_history AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_spent,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS purchase_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk IS NOT NULL
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        total_quantity,
        total_spent,
        purchase_rank
    FROM 
        purchase_history
    WHERE 
        purchase_rank <= 10
),
store_overview AS (
    SELECT 
        s.s_store_sk,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_sales,
        SUM(ss.ss_sales_price) AS total_revenue,
        AVG(ss.ss_net_profit) AS avg_profit
    FROM 
        store s
    LEFT JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    WHERE 
        ss.ss_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        s.s_store_sk
),
customer_locations AS (
    SELECT 
        c.c_customer_sk,
        ca.ca_city,
        ca.ca_state,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, ca.ca_city, ca.ca_state
),
city_performance AS (
    SELECT 
        ca.ca_city,
        ca.ca_state,
        SUM(ws.ws_sales_price) AS total_city_sales,
        COUNT(DISTINCT CASE WHEN ws.ws_net_paid > 0 THEN ws.ws_order_number END) AS count_positive_orders,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM 
        customer_address ca
    LEFT JOIN 
        web_sales ws ON ca.ca_address_sk = ws.ws_ship_addr_sk
    GROUP BY 
        ca.ca_city, ca.ca_state
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    loc.ca_city,
    loc.ca_state,
    COALESCE(sp.total_sales, 0) AS store_sales,
    COALESCE(sp.total_revenue, 0) AS store_revenue,
    COALESCE(cp.total_city_sales, 0) AS city_sales,
    COALESCE(cp.count_positive_orders, 0) AS city_positive_count,
    COALESCE(cp.avg_net_profit, 0) AS city_avg_net_profit
FROM 
    top_customers tc
LEFT JOIN 
    customer_locations loc ON tc.c_customer_sk = loc.c_customer_sk
LEFT JOIN 
    store_overview sp ON sp.total_sales = (
        SELECT MAX(total_sales) FROM store_overview
    )
LEFT JOIN 
    city_performance cp ON loc.ca_city = cp.ca_city AND loc.ca_state = cp.ca_state
WHERE 
    (tc.total_spent > 1000 OR loc.order_count > 5)
ORDER BY 
    tc.total_spent DESC, 
    loc.ca_city ASC;
