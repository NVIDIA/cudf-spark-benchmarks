
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_sales_price) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        c.c_customer_sk
),
TopCustomer AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_web_sales,
        cs.web_order_count,
        RANK() OVER (ORDER BY cs.total_web_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
),
FrequentItems AS (
    SELECT 
        ws.ws_item_sk,
        COUNT(ws.ws_order_number) AS order_count,
        SUM(ws.ws_sales_price) AS total_sales
    FROM 
        web_sales ws
    JOIN 
        TopCustomer tc ON ws.ws_ship_customer_sk = tc.c_customer_sk
    GROUP BY 
        ws.ws_item_sk
),
TopItems AS (
    SELECT 
        i.i_item_id,
        fi.order_count,
        fi.total_sales,
        RANK() OVER (ORDER BY fi.total_sales DESC) AS item_rank
    FROM 
        FrequentItems fi
    JOIN 
        item i ON fi.ws_item_sk = i.i_item_sk
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    ti.i_item_id,
    ti.order_count,
    ti.total_sales
FROM 
    TopCustomer tc
JOIN 
    TopItems ti ON tc.sales_rank <= 10 AND ti.item_rank <= 10
ORDER BY 
    tc.sales_rank, ti.item_rank;
