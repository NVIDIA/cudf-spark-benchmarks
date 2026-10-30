
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS sales_rank
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
        cs.total_sales,
        cs.order_count
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.sales_rank <= 10
),
SalesAnalysis AS (
    SELECT 
        t.d_year,
        SUM(ws.ws_net_profit) AS yearly_sales,
        AVG(ws.ws_net_profit) AS avg_sales_per_order
    FROM 
        web_sales ws
    JOIN 
        date_dim t ON ws.ws_sold_date_sk = t.d_date_sk
    GROUP BY 
        t.d_year
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    ta.yearly_sales,
    ta.avg_sales_per_order,
    CASE 
        WHEN tc.total_sales > ta.yearly_sales THEN 'Above Average'
        ELSE 'Below Average'
    END AS performance_category
FROM 
    TopCustomers tc
LEFT JOIN 
    SalesAnalysis ta ON tc.total_sales > ta.yearly_sales
ORDER BY 
    tc.total_sales DESC, 
    tc.order_count DESC;
