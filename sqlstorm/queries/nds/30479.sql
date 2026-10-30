
WITH  SalesCTE AS (
    SELECT 
        ws_item_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rn
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
), 
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_net_paid) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
), 
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_orders,
        cs.total_spent,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS rank
    FROM 
        customer c
    JOIN 
        CustomerStats cs ON c.c_customer_sk = cs.c_customer_sk
)
SELECT 
    cu.c_first_name,
    cu.c_last_name,
    cu.total_orders,
    cu.total_spent,
    COALESCE(SUM(st.ss_sales_price), 0) AS total_store_sales,
    COALESCE(SUM(sr.sr_return_amt), 0) AS total_return_sales,
    CASE 
        WHEN cu.total_spent > 1000 THEN 'High Value'
        WHEN cu.total_spent BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM 
    TopCustomers cu
LEFT JOIN 
    store_sales st ON cu.c_customer_sk = st.ss_customer_sk
LEFT JOIN 
    store_returns sr ON cu.c_customer_sk = sr.sr_customer_sk
WHERE 
    cu.rank <= 10
GROUP BY 
    cu.c_first_name, cu.c_last_name, cu.total_orders, cu.total_spent
ORDER BY 
    cu.total_spent DESC;
