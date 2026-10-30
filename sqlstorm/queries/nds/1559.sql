
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_profit,
        cs.total_orders,
        RANK() OVER (ORDER BY cs.total_profit DESC) AS customer_rank
    FROM 
        CustomerSales cs
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_profit,
    tc.total_orders,
    COALESCE(w.web_name, 'No Website') AS web_name,
    CAST(dd.d_date AS DATE) AS sales_date,
    COALESCE(sm.sm_carrier, 'Not Specified') AS shipping_method,
    COUNT(DISTINCT ws.ws_order_number) AS total_web_orders,
    SUM(ws.ws_net_paid_inc_tax) AS total_web_revenue
FROM 
    TopCustomers tc
LEFT JOIN 
    web_sales ws ON tc.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    web_site w ON ws.ws_web_site_sk = w.web_site_sk
LEFT JOIN 
    date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
LEFT JOIN 
    ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
WHERE 
    tc.customer_rank <= 10
    AND (dd.d_year = 2023 OR dd.d_year IS NULL)
GROUP BY 
    tc.c_first_name, tc.c_last_name, tc.total_profit, tc.total_orders, w.web_name, dd.d_date, sm.sm_carrier
ORDER BY 
    tc.total_profit DESC;
