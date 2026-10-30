
WITH SalesSummary AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_sales_price) AS Total_Sales,
        COUNT(ws.ws_order_number) AS Order_Count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        ss.Total_Sales,
        ss.Order_Count,
        RANK() OVER (ORDER BY ss.Total_Sales DESC) AS Sales_Rank
    FROM 
        SalesSummary ss
    JOIN 
        customer c ON ss.c_customer_id = c.c_customer_id
    WHERE 
        ss.Total_Sales IS NOT NULL
)
SELECT 
    tc.c_customer_id,
    tc.Total_Sales,
    tc.Order_Count,
    tc.Sales_Rank,
    ca.ca_city,
    ca.ca_state
FROM 
    TopCustomers tc
JOIN 
    customer_address ca ON tc.c_customer_id = ca.ca_address_id
WHERE 
    tc.Sales_Rank <= 10
    AND (ca.ca_state = 'CA' OR ca.ca_state = 'NY')
ORDER BY 
    tc.Total_Sales DESC;
