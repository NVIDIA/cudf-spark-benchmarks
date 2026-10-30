
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        DENSE_RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_net_profit,
        cs.total_orders
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.profit_rank <= 10
),
SalesInfo AS (
    SELECT 
        ws.ws_sold_date_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_profit) AS total_net_profit_from_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_sales_orders
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_sold_date_sk
),
HighestSalesDay AS (
    SELECT 
        d.d_date,
        si.total_quantity_sold,
        si.total_net_profit_from_sales,
        si.total_sales_orders
    FROM 
        SalesInfo si
    JOIN 
        date_dim d ON si.ws_sold_date_sk = d.d_date_sk
    ORDER BY 
        si.total_net_profit_from_sales DESC
    LIMIT 1
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    hsd.d_date AS highest_sales_date,
    hsd.total_quantity_sold,
    hsd.total_net_profit_from_sales
FROM 
    TopCustomers tc
CROSS JOIN 
    HighestSalesDay hsd
ORDER BY 
    tc.total_net_profit DESC;
