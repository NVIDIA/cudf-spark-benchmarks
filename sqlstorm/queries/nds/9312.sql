
WITH Customer_Sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
Top_Customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        Customer_Sales cs
),
Sales_By_City AS (
    SELECT 
        ca.ca_city,
        COUNT(DISTINCT c.c_customer_sk) AS num_customers,
        SUM(ws.ws_ext_sales_price) AS total_sales_city
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        ca.ca_city
),
Overall_Sales AS (
    SELECT 
        SUM(ws.ws_ext_sales_price) AS total_net_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    sbc.num_customers AS customers_in_city,
    sbc.total_sales_city AS sales_in_city,
    os.total_net_sales,
    os.total_orders
FROM 
    Top_Customers tc
JOIN 
    Sales_By_City sbc ON tc.c_customer_sk IN (SELECT c.c_customer_sk FROM customer c JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk WHERE ca.ca_city = 'Los Angeles') 
CROSS JOIN 
    Overall_Sales os
WHERE 
    tc.sales_rank <= 10;
