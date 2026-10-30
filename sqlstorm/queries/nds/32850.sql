
WITH  Sales_CTE AS (
    SELECT 
        ss_item_sk, 
        SUM(ss_net_paid) AS total_sales,
        COUNT(ss_ticket_number) AS total_transactions,
        ROW_NUMBER() OVER (PARTITION BY ss_item_sk ORDER BY SUM(ss_net_paid) DESC) AS rank
    FROM 
        store_sales
    GROUP BY 
        ss_item_sk
),
High_Sellers AS (
    SELECT 
        sc.ss_item_sk,
        sc.total_sales,
        sc.total_transactions,
        i.i_item_desc,
        ROW_NUMBER() OVER (ORDER BY sc.total_sales DESC) AS item_rank
    FROM 
        Sales_CTE sc
    JOIN 
        item i ON sc.ss_item_sk = i.i_item_sk
    WHERE 
        sc.rank <= 10
),
Customer_Summary AS (
    SELECT
        c.c_customer_sk,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
Top_Customers AS (
    SELECT 
        cus.c_customer_sk,
        cus.total_orders,
        cus.total_spent,
        DENSE_RANK() OVER (ORDER BY cus.total_spent DESC) AS customer_rank
    FROM 
        Customer_Summary cus
    WHERE 
        cus.total_spent > 1000
)
SELECT 
    h.item_rank,
    h.i_item_desc,
    h.total_sales,
    tc.customer_rank,
    tc.total_spent
FROM 
    High_Sellers h
FULL OUTER JOIN 
    Top_Customers tc ON h.ss_item_sk = tc.c_customer_sk
WHERE 
    (h.total_sales IS NOT NULL OR tc.total_spent IS NOT NULL)
ORDER BY 
    COALESCE(h.item_rank, 9999), 
    COALESCE(tc.customer_rank, 9999);
