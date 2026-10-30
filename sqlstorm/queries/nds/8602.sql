
WITH Customer_Sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_item_sk) AS items_purchased,
        AVG(ws.ws_sales_price) AS avg_item_price
    FROM
        customer AS c
    JOIN
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE
        c.c_birth_year > 1980 
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
Top_Customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_sales,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        Customer_Sales AS cs
    JOIN 
        customer AS c ON cs.c_customer_sk = c.c_customer_sk
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales
FROM 
    Top_Customers AS tc
WHERE 
    tc.sales_rank <= 10
ORDER BY 
    tc.total_sales DESC;
