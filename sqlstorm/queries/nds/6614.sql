
WITH CustomerOrders AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        co.c_customer_sk,
        co.c_first_name,
        co.c_last_name,
        co.total_sales,
        co.order_count,
        ROW_NUMBER() OVER (ORDER BY co.total_sales DESC) AS sales_rank
    FROM 
        CustomerOrders co
    WHERE 
        co.total_sales > 1000
),
FrequentItems AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales
    FROM 
        web_sales ws
    JOIN 
        TopCustomers tc ON ws.ws_bill_customer_sk = tc.c_customer_sk
    GROUP BY 
        ws.ws_item_sk
    HAVING 
        SUM(ws.ws_quantity) > 10
),
ItemDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        fi.total_quantity,
        fi.total_sales
    FROM 
        item i
    JOIN 
        FrequentItems fi ON i.i_item_sk = fi.ws_item_sk
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    id.i_item_desc,
    id.total_quantity,
    id.total_sales,
    tc.total_sales AS customer_total_sales
FROM 
    TopCustomers tc
JOIN 
    ItemDetails id ON tc.c_customer_sk = id.i_item_sk
WHERE 
    tc.sales_rank <= 10
ORDER BY 
    tc.total_sales DESC, id.total_sales DESC;
