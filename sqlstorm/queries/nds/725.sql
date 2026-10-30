
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        COUNT(ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS customer_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk AS customer_sk,
        c.c_first_name AS first_name,
        c.c_last_name AS last_name,
        c.total_spent,
        c.total_orders,
        (SELECT COUNT(*) FROM CustomerSales) AS total_customers
    FROM 
        CustomerSales c
    WHERE 
        c.customer_rank <= 10
),
SalesSummary AS (
    SELECT 
        dd.d_year,
        SUM(ws.ws_net_paid_inc_tax) AS yearly_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid) AS avg_order_value
    FROM 
        date_dim dd
    LEFT JOIN 
        web_sales ws ON dd.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        dd.d_year
)
SELECT 
    tc.first_name,
    tc.last_name,
    tc.total_spent,
    tc.total_orders,
    ss.yearly_sales,
    ss.total_orders AS yearly_total_orders,
    ss.avg_order_value
FROM 
    TopCustomers tc
JOIN 
    SalesSummary ss ON ss.yearly_sales > 50000
WHERE 
    tc.total_spent IS NOT NULL
ORDER BY 
    tc.total_spent DESC
LIMIT 20;
