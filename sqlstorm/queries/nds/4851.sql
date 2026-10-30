
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
HighSpendingCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_sales
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.total_sales > (SELECT AVG(total_sales) FROM CustomerSales)
),
TopProducts AS (
    SELECT 
        i.i_item_sk,
        i.i_product_name,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        ROW_NUMBER() OVER (ORDER BY SUM(ws.ws_quantity) DESC) AS rank
    FROM 
        item i
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_sk, i.i_product_name
    HAVING 
        SUM(ws.ws_quantity) > 100
)
SELECT 
    h.c_customer_sk,
    h.c_first_name,
    h.c_last_name,
    h.total_sales,
    p.i_product_name,
    p.total_quantity_sold
FROM 
    HighSpendingCustomers h
JOIN 
    TopProducts p ON p.rank <= 5
LEFT JOIN 
    store s ON s.s_store_sk = p.i_item_sk % 100 
WHERE 
    h.total_sales > (
        SELECT AVG(total_sales) FROM CustomerSales
        WHERE c_customer_sk = h.c_customer_sk
    ) 
ORDER BY 
    h.total_sales DESC, p.total_quantity_sold DESC;
