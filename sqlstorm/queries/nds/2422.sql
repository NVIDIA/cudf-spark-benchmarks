
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_net_profit,
        cs.total_orders,
        RANK() OVER (ORDER BY cs.total_net_profit DESC) AS rank
    FROM 
        CustomerSales cs
    WHERE 
        cs.total_net_profit IS NOT NULL
),
SalesByMonth AS (
    SELECT 
        dd.d_year,
        dd.d_month_seq,
        COUNT(ws.ws_order_number) AS total_sales,
        SUM(ws.ws_net_paid_inc_tax) AS total_revenue
    FROM 
        date_dim dd
    LEFT JOIN 
        web_sales ws ON dd.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        dd.d_year, dd.d_month_seq
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_net_profit,
    tc.total_orders,
    sbm.total_sales,
    sbm.total_revenue,
    COALESCE(sbm.total_revenue / NULLIF(sbm.total_sales, 0), 0) AS average_sale_value
FROM 
    TopCustomers tc
FULL OUTER JOIN 
    SalesByMonth sbm ON tc.rank <= 10 AND sbm.d_year = 2023
WHERE 
    (tc.total_net_profit > 1000 OR sbm.total_sales IS NOT NULL)
ORDER BY 
    tc.rank, sbm.d_month_seq;
