
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1970 AND 1980
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
ProminentCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        cs.order_count,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
    WHERE 
        cs.total_sales > (SELECT AVG(total_sales) FROM CustomerSales)
),
SalesDetails AS (
    SELECT 
        pc.c_customer_sk,
        pc.c_first_name,
        pc.c_last_name,
        pc.total_sales,
        pc.order_count,
        ARRAY_AGG(ws.ws_order_number) AS order_ids
    FROM 
        ProminentCustomers pc
    JOIN 
        web_sales ws ON pc.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        pc.c_customer_sk, pc.c_first_name, pc.c_last_name, pc.total_sales, pc.order_count
)
SELECT 
    sd.c_customer_sk,
    sd.c_first_name,
    sd.c_last_name,
    sd.total_sales,
    sd.order_count,
    sd.order_ids,
    COUNT(DISTINCT ws.ws_item_sk) AS unique_items_purchased
FROM 
    SalesDetails sd
JOIN 
    web_sales ws ON sd.c_customer_sk = ws.ws_bill_customer_sk
GROUP BY 
    sd.c_customer_sk, sd.c_first_name, sd.c_last_name, sd.total_sales, sd.order_count, sd.order_ids
ORDER BY 
    sd.total_sales DESC
LIMIT 100;
