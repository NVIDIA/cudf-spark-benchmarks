
WITH  Sales_CTE AS (
    SELECT 
        ws_item_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
Detailed_Customer_Sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(COALESCE(ws.ws_net_paid, 0)) AS total_spent,
        COUNT(ws.ws_order_number) AS orders_count,
        MAX(ws.ws_sold_date_sk) AS last_purchase_date
    FROM 
        customer AS c
    LEFT JOIN web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
High_Value_Customers AS (
    SELECT 
        customer.c_customer_sk,
        customer.c_first_name,
        customer.c_last_name,
        customer.total_spent,
        DENSE_RANK() OVER (ORDER BY customer.total_spent DESC) AS spending_rank
    FROM 
        Detailed_Customer_Sales AS customer
    WHERE 
        customer.total_spent > (SELECT AVG(total_spent) FROM Detailed_Customer_Sales)
),
Inventory_Status AS (
    SELECT 
        i.i_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_stock
    FROM 
        item AS i
    JOIN inventory AS inv ON i.i_item_sk = inv.inv_item_sk
    GROUP BY 
        i.i_item_sk
)
SELECT 
    hs.c_customer_sk,
    hs.c_first_name,
    hs.c_last_name,
    s.total_profit,
    s.order_count,
    inv.total_stock
FROM 
    High_Value_Customers AS hs
JOIN 
    Sales_CTE AS s ON hs.c_customer_sk = s.ws_item_sk
LEFT JOIN 
    Inventory_Status AS inv ON s.ws_item_sk = inv.i_item_sk
WHERE 
    inv.total_stock IS NOT NULL
ORDER BY 
    hs.spending_rank, s.total_profit DESC;
