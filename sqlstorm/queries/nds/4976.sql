
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(COALESCE(ws_ext_sales_price, 0) + COALESCE(cs_ext_sales_price, 0) + COALESCE(ss_ext_sales_price, 0)) AS total_sales,
        COUNT(DISTINCT CASE WHEN ws_order_number IS NOT NULL THEN ws_order_number END) AS online_orders,
        COUNT(DISTINCT CASE WHEN cs_order_number IS NOT NULL THEN cs_order_number END) AS catalog_orders,
        COUNT(DISTINCT CASE WHEN ss_ticket_number IS NOT NULL THEN ss_ticket_number END) AS store_orders
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
),
SalesAnalysis AS (
    SELECT 
        cs.*, 
        DENSE_RANK() OVER (ORDER BY total_sales DESC) AS sales_rank,
        CASE 
            WHEN total_sales > 10000 THEN 'High Value'
            WHEN total_sales BETWEEN 5000 AND 10000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value_band
    FROM 
        CustomerSales cs
)
SELECT 
    sa.c_customer_id,
    sa.c_first_name,
    sa.c_last_name,
    sa.total_sales,
    sa.online_orders,
    sa.catalog_orders,
    sa.store_orders,
    sa.sales_rank,
    sa.customer_value_band
FROM 
    SalesAnalysis sa
WHERE 
    sa.sales_rank <= 10 
    AND sa.customer_value_band = 'High Value'
ORDER BY 
    sa.total_sales DESC;
