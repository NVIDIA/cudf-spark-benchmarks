
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_current_addr_sk,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_addr_sk
),
AddressSales AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        SUM(cs.cs_net_paid_inc_tax) AS total_catalog_sales
    FROM 
        customer_address ca
    LEFT JOIN 
        catalog_sales cs ON ca.ca_address_sk = cs.cs_bill_addr_sk
    GROUP BY 
        ca.ca_address_sk, ca.ca_city, ca.ca_state
),
SalesMetrics AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        COALESCE(asales.total_catalog_sales, 0) AS catalog_sales,
        cs.total_sales,
        cs.total_orders,
        CASE 
            WHEN cs.total_sales > 1000 THEN 'High Value'
            WHEN cs.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS sales_category
    FROM 
        CustomerSales cs
    LEFT JOIN 
        AddressSales asales ON cs.c_current_addr_sk = asales.ca_address_sk
)
SELECT 
    sm.c_customer_sk,
    sm.c_first_name || ' ' || sm.c_last_name AS full_name,
    sm.catalog_sales,
    sm.total_sales,
    sm.total_orders,
    sm.sales_category,
    RANK() OVER (PARTITION BY sm.sales_category ORDER BY sm.total_sales DESC) AS sales_rank
FROM 
    SalesMetrics sm
WHERE 
    sm.catalog_sales > 0
ORDER BY 
    sm.sales_category, sales_rank;
