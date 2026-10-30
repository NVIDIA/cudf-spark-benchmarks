
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS full_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT(ws.ws_order_number)) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_salutation, c.c_first_name, c.c_last_name
), HighSpenders AS (
    SELECT 
        cs.c_customer_sk,
        cs.full_name,
        cs.total_sales,
        ROW_NUMBER() OVER (ORDER BY cs.total_sales DESC) AS rn
    FROM 
        CustomerSales cs
    WHERE 
        cs.total_sales > (
            SELECT AVG(total_sales) FROM CustomerSales
        )
)
SELECT 
    h.full_name,
    h.total_sales,
    COUNT(DISTINCT s.ss_store_sk) AS unique_stores,
    MAX(s.ss_sold_date_sk) AS last_purchase_date
FROM 
    HighSpenders h
JOIN 
    store_sales s ON h.c_customer_sk = s.ss_customer_sk
GROUP BY 
    h.c_customer_sk, h.full_name, h.total_sales
ORDER BY 
    h.total_sales DESC
LIMIT 10;
