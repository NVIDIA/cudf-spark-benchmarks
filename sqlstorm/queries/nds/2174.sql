
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS Total_Sales,
        COUNT(DISTINCT ws.ws_order_number) AS Order_Count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.Total_Sales,
        cs.Order_Count,
        DENSE_RANK() OVER (ORDER BY cs.Total_Sales DESC) AS Sales_Rank
    FROM 
        CustomerSales cs
    INNER JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.Total_Sales > 1000
)
SELECT 
    hvc.c_customer_sk,
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.Total_Sales,
    hvc.Order_Count,
    hvc.Sales_Rank,
    COALESCE((SELECT 
                  AVG(ws.ws_net_paid) 
              FROM 
                  web_sales ws 
              WHERE 
                  ws.ws_ship_customer_sk = hvc.c_customer_sk), 0) AS Avg_Purchase_Amount
FROM 
    HighValueCustomers hvc
ORDER BY 
    hvc.Sales_Rank
LIMIT 10;
