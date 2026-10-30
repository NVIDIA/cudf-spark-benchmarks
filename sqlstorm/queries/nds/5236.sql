
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT(ws.ws_order_number)) AS total_orders,
        COUNT(DISTINCT(ws.ws_item_sk)) AS distinct_items,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year >= 1980
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
), 
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_net_profit,
        cs.total_orders,
        cs.distinct_items,
        cs.avg_sales_price,
        ROW_NUMBER() OVER (ORDER BY cs.total_net_profit DESC) AS rn
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_net_profit,
    tc.total_orders,
    tc.distinct_items,
    tc.avg_sales_price
FROM 
    TopCustomers tc
WHERE 
    tc.rn <= 10
ORDER BY 
    tc.total_net_profit DESC;

