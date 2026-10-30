
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        MAX(d.d_date) AS last_order_date
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        c.*,
        ROW_NUMBER() OVER (ORDER BY c.total_sales DESC) AS rnk
    FROM 
        CustomerSales c
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    tc.order_count,
    COALESCE(d.ca_city, 'Unknown') AS city,
    COALESCE(d.ca_state, 'Unknown') AS state
FROM 
    TopCustomers tc
LEFT JOIN 
    customer_address d ON tc.c_customer_sk = d.ca_address_sk
WHERE 
    tc.rnk <= 10
ORDER BY 
    total_sales DESC;
