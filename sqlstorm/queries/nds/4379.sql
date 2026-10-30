
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
), 
TopCustomers AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        CustomerSales
),
SalesByShippingMethod AS (
    SELECT 
        sm.sm_type,
        SUM(ws.ws_net_paid) AS sales_amount,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    JOIN 
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY 
        sm.sm_type
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    tc.order_count,
    CASE 
        WHEN tc.total_sales IS NULL THEN 'No Sales'
        WHEN tc.sales_rank <= 10 THEN 'Top Customer'
        ELSE 'Regular Customer'
    END AS customer_status,
    s.sm_type,
    s.sales_amount AS shipping_sales
FROM 
    TopCustomers tc
LEFT OUTER JOIN 
    SalesByShippingMethod s ON s.order_count > 0
WHERE 
    tc.sales_rank <= 20 OR s.sales_amount > 1000
ORDER BY 
    tc.total_sales DESC, s.sales_amount DESC;
