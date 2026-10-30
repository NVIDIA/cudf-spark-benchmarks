
WITH  Sales_CTE AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales 
    WHERE 
        ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk
), 
Top_Sales AS (
    SELECT 
        ws_item_sk,
        total_sales,
        order_count
    FROM 
        Sales_CTE
    WHERE 
        sales_rank <= 10
),
Customer_Info AS (
    SELECT 
        c_customer_sk,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_ext_sales_price) AS total_spent,
        AVG(ws_ext_sales_price) AS avg_order_value
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        c_customer_sk
)
SELECT 
    t.ws_item_sk,
    t.total_sales,
    c.total_orders,
    c.total_spent,
    CASE 
        WHEN c.total_spent IS NULL THEN 'No Orders'
        ELSE CAST(c.total_spent AS STRING)
    END AS spending_case
FROM 
    Top_Sales t
LEFT JOIN 
    Customer_Info c ON t.ws_item_sk = c.total_orders
WHERE 
    t.total_sales > 1000
ORDER BY 
    t.total_sales DESC;
