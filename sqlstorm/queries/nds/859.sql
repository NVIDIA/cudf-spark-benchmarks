
WITH Customer_Sales AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_first_shipto_date_sk IS NOT NULL
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
Top_Customers AS (
    SELECT 
        c.c_customer_sk,
        cs.customer_name,
        cs.total_spent,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY cs.total_spent DESC) AS rnk
    FROM 
        customer c
    JOIN 
        Customer_Sales cs ON c.c_customer_sk = cs.c_customer_sk
),
Returned_Items AS (
    SELECT 
        wr.wr_returning_customer_sk,
        SUM(wr.wr_return_quantity) AS total_returns,
        SUM(wr.wr_return_amt) AS total_return_amount
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_returning_customer_sk
),
Sales_Summary AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_spent,
        COALESCE(ri.total_returns, 0) AS total_returns,
        COALESCE(ri.total_return_amount, 0) AS total_return_amount,
        (cs.total_spent - COALESCE(ri.total_return_amount, 0)) AS net_spent
    FROM 
        Customer_Sales cs
    LEFT JOIN 
        Returned_Items ri ON cs.c_customer_sk = ri.wr_returning_customer_sk
)
SELECT 
    t.customer_name,
    t.total_spent,
    s.total_returns,
    s.total_return_amount,
    s.net_spent
FROM 
    Top_Customers t
JOIN 
    Sales_Summary s ON t.c_customer_sk = s.c_customer_sk
WHERE 
    t.rnk = 1 
    AND t.total_spent > 100
ORDER BY 
    s.net_spent DESC
LIMIT 10;
