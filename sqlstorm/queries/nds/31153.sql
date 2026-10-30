
WITH  SalesCTE AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        d_year,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    JOIN 
        date_dim ON ws_sold_date_sk = d_date_sk
    WHERE 
        d_year >= 2021
    GROUP BY 
        ws_item_sk, d_year
), 
CustomerActivity AS (
    SELECT 
        c_customer_sk,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_net_paid) AS total_spent
    FROM 
        customer
    JOIN 
        web_sales ON c_customer_sk = ws_ship_customer_sk
    GROUP BY 
        c_customer_sk
),
TopCustomers AS (
    SELECT 
        ca.c_customer_sk,
        ca.total_orders,
        ca.total_spent,
        ROW_NUMBER() OVER (ORDER BY ca.total_spent DESC) as customer_rank
    FROM 
        CustomerActivity ca
    WHERE 
        ca.total_orders > 5
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    ca.total_orders,
    ca.total_spent,
    COALESCE(p.p_discount_active, 'N') AS discount_active,
    COALESCE(s.total_sales, 0) AS total_sales_amount
FROM 
    customer c
LEFT JOIN 
    TopCustomers ca ON c.c_customer_sk = ca.c_customer_sk
LEFT JOIN 
    (SELECT ws_item_sk, SUM(ws_sales_price) AS total_sales 
     FROM web_sales 
     WHERE ws_sales_price > 0 
     GROUP BY ws_item_sk) s ON s.ws_item_sk IN (SELECT ws_item_sk FROM SalesCTE WHERE sales_rank <= 10)
LEFT JOIN 
    promotion p ON p.p_item_sk IN (SELECT ws_item_sk FROM SalesCTE WHERE sales_rank <= 10)
WHERE 
    ca.customer_rank <= 100
ORDER BY 
    ca.total_spent DESC, c.c_last_name;
