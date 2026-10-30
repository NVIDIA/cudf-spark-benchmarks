
WITH  sales_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        SUM(ss.ss_net_paid) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ss.ss_net_paid) DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_customer_id
), 
top_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        s.total_sales
    FROM 
        sales_hierarchy s
    INNER JOIN 
        customer c ON s.c_customer_sk = c.c_customer_sk
    WHERE 
        s.sales_rank <= 10
), 
sales_summary AS (
    SELECT 
        DATE_DIM.d_year,
        SUM(ws.ws_net_paid) AS web_sales_total,
        AVG(ss.ss_net_paid) AS average_store_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_store_transactions,
        COUNT(DISTINCT ws.ws_order_number) AS total_web_transactions
    FROM 
        date_dim DATE_DIM 
    LEFT JOIN 
        web_sales ws ON DATE_DIM.d_date_sk = ws.ws_sold_date_sk
    LEFT JOIN 
        store_sales ss ON DATE_DIM.d_date_sk = ss.ss_sold_date_sk
    GROUP BY 
        DATE_DIM.d_year
)
SELECT 
    w.w_warehouse_id,
    w.w_warehouse_name,
    w.w_city,
    COALESCE(ts.total_sales, 0) AS top_customer_sales,
    COALESCE(ss.web_sales_total, 0) AS total_web_sales,
    COALESCE(ss.average_store_sales, 0) AS average_store_sales,
    ss.total_store_transactions,
    ss.total_web_transactions,
    COUNT(s.ss_item_sk) AS total_items_sold,
    MAX(s.ss_ext_discount_amt) AS max_discount,
    SUM(CASE WHEN s.ss_sales_price IS NULL THEN 0 ELSE s.ss_sales_price END) AS total_sales_value,
    STRING_AGG(DISTINCT i.i_item_desc, ', ') AS sold_items
FROM 
    warehouse w
LEFT JOIN 
    store_sales s ON w.w_warehouse_sk = s.ss_store_sk
FULL OUTER JOIN 
    top_customers ts ON s.ss_customer_sk = ts.c_customer_sk
LEFT JOIN 
    sales_summary ss ON ss.d_year = EXTRACT(YEAR FROM '2002-10-01'::date)
LEFT JOIN 
    item i ON s.ss_item_sk = i.i_item_sk
WHERE 
    w.w_country = 'USA'
GROUP BY 
    w.w_warehouse_id, w.w_warehouse_name, w.w_city, ts.total_sales, ss.web_sales_total, ss.average_store_sales, ss.total_store_transactions, ss.total_web_transactions
ORDER BY 
    total_sales_value DESC
LIMIT 10;
