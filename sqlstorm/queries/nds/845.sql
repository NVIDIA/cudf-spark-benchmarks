
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_ship_date_sk) AS total_ship_dates
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) - 30 
                                FROM date_dim d)
    GROUP BY 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name
), StoreSales AS (
    SELECT 
        ss.ss_customer_sk,
        SUM(ss.ss_ext_sales_price) AS total_store_sales
    FROM 
        store_sales ss
    GROUP BY 
        ss.ss_customer_sk
), CombinedSales AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_web_sales,
        COALESCE(ss.total_store_sales, 0) AS total_store_sales,
        (cs.total_web_sales + COALESCE(ss.total_store_sales, 0)) AS total_sales
    FROM 
        CustomerSales cs
    LEFT JOIN 
        StoreSales ss ON cs.c_customer_sk = ss.ss_customer_sk
)

SELECT 
    c.c_customer_sk AS c_customer_id,
    c.c_first_name,
    c.c_last_name,
    c.total_sales,
    RANK() OVER (ORDER BY c.total_sales DESC) AS sales_rank,
    CASE 
        WHEN c.total_sales > 1000 THEN 'High Value'
        WHEN c.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM 
    CombinedSales c
WHERE 
    c.total_sales IS NOT NULL
ORDER BY 
    c.total_sales DESC
LIMIT 10;
