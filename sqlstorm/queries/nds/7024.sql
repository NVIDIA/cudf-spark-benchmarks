
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(ss.ss_ext_sales_price) AS total_store_sales
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id
),
SalesDetails AS (
    SELECT 
        c.c_customer_id,
        ca.ca_city,
        ca.ca_state,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(ss.ss_ext_sales_price) AS total_store_sales
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        ca.ca_state IN ('CA', 'NY', 'TX')
    GROUP BY 
        c.c_customer_id, ca.ca_city, ca.ca_state
)
SELECT 
    sd.c_customer_id,
    sd.ca_city,
    sd.ca_state,
    sd.total_web_sales,
    sd.total_catalog_sales,
    sd.total_store_sales,
    (COALESCE(sd.total_web_sales, 0) + COALESCE(sd.total_catalog_sales, 0) + COALESCE(sd.total_store_sales, 0)) AS total_sales,
    CASE 
        WHEN (COALESCE(sd.total_web_sales, 0) + COALESCE(sd.total_catalog_sales, 0) + COALESCE(sd.total_store_sales, 0)) > 100000 THEN 'High Value Customer'
        WHEN (COALESCE(sd.total_web_sales, 0) + COALESCE(sd.total_catalog_sales, 0) + COALESCE(sd.total_store_sales, 0)) > 50000 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_value_flag
FROM 
    SalesDetails sd
WHERE 
    sd.total_web_sales > 0 OR sd.total_catalog_sales > 0 OR sd.total_store_sales > 0
ORDER BY 
    total_sales DESC
LIMIT 100;
