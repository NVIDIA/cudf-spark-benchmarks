
WITH  sales_summary AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
), 
high_value_customers AS (
    SELECT 
        cs_bill_customer_sk AS customer_sk,
        SUM(cs_ext_sales_price) AS total_catalog_sales
    FROM 
        catalog_sales
    GROUP BY 
        cs_bill_customer_sk
    HAVING 
        SUM(cs_ext_sales_price) > 1000
), 
final_summary AS (
    SELECT 
        c.c_customer_id,
        ca.ca_city,
        COALESCE(ss.total_sales, 0) AS total_web_sales,
        COALESCE(hv.total_catalog_sales, 0) AS total_catalog_sales,
        CASE 
            WHEN ss.rank IS NOT NULL THEN 'Web Customer'
            ELSE 'Catalog Customer'
        END AS customer_type
    FROM 
        customer c
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        sales_summary ss ON c.c_customer_sk = ss.customer_sk
    LEFT JOIN 
        high_value_customers hv ON c.c_customer_sk = hv.customer_sk
)
SELECT 
    c_customer_id,
    ca_city,
    total_web_sales,
    total_catalog_sales,
    customer_type,
    CASE 
        WHEN total_web_sales > total_catalog_sales THEN 'Web Dominant'
        WHEN total_catalog_sales > total_web_sales THEN 'Catalog Dominant'
        ELSE 'Equal Contribution'
    END AS sales_type
FROM 
    final_summary
WHERE 
    (total_web_sales + total_catalog_sales) > 0
ORDER BY 
    total_web_sales DESC, total_catalog_sales DESC
LIMIT 100;
