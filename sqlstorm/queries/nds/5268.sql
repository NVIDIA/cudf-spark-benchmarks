
WITH SalesSummary AS (
    SELECT 
        c.c_customer_id,
        SUM(CASE WHEN ws.ws_sold_date_sk IS NOT NULL THEN ws.ws_ext_sales_price ELSE 0 END) AS total_web_sales,
        SUM(CASE WHEN cs.cs_sold_date_sk IS NOT NULL THEN cs.cs_ext_sales_price ELSE 0 END) AS total_catalog_sales,
        SUM(CASE WHEN ss.ss_sold_date_sk IS NOT NULL THEN ss.ss_ext_sales_price ELSE 0 END) AS total_store_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_web_orders,
        COUNT(DISTINCT cs.cs_order_number) AS total_catalog_orders,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_store_orders
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        c.c_current_addr_sk IS NOT NULL
    GROUP BY 
        c.c_customer_id
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    SUM(ss.total_web_sales) AS total_web_sales_by_city,
    SUM(ss.total_catalog_sales) AS total_catalog_sales_by_city,
    SUM(ss.total_store_sales) AS total_store_sales_by_city,
    SUM(ss.total_web_orders) AS total_web_orders_by_city,
    SUM(ss.total_catalog_orders) AS total_catalog_orders_by_city,
    SUM(ss.total_store_orders) AS total_store_orders_by_city
FROM 
    SalesSummary ss
JOIN 
    customer_address ca ON ss.c_customer_id = ca.ca_address_id
GROUP BY 
    ca.ca_city, ca.ca_state
ORDER BY 
    total_web_sales_by_city DESC, total_catalog_sales_by_city DESC, total_store_sales_by_city DESC
LIMIT 10;
