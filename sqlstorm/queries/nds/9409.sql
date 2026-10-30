
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cs.total_sales, 
        cs.order_count,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        customer_sales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
),
popular_items AS (
    SELECT 
        ws.ws_item_sk,
        i.i_item_desc,
        SUM(ws.ws_quantity) AS total_quantity_sold
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY 
        ws.ws_item_sk, i.i_item_desc
    ORDER BY 
        total_quantity_sold DESC
    LIMIT 10
),
sales_by_region AS (
    SELECT 
        ca.ca_state,
        SUM(ws.ws_net_paid) AS total_sales
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        ca.ca_state
)
SELECT 
    tc.c_first_name AS customer_first_name,
    tc.c_last_name AS customer_last_name,
    tc.total_sales AS customer_total_sales,
    tc.order_count AS customer_order_count,
    pi.i_item_desc AS popular_item_description,
    sr.ca_state AS sales_region,
    sr.total_sales AS region_total_sales
FROM 
    top_customers tc
CROSS JOIN 
    popular_items pi
JOIN 
    sales_by_region sr ON sr.total_sales > 10000
WHERE 
    tc.sales_rank <= 10
ORDER BY 
    tc.total_sales DESC, sr.total_sales DESC;
