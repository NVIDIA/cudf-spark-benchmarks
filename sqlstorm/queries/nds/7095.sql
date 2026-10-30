
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid_inc_tax) AS avg_spent,
        MAX(ws.ws_sales_price) AS max_item_price,
        MIN(ws.ws_sales_price) AS min_item_price
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023 AND
        dd.d_moy BETWEEN 1 AND 6
    GROUP BY 
        c.c_customer_id
),
TopCustomers AS (
    SELECT 
        c.c_customer_id AS customer_id,
        c.total_net_profit,
        c.total_orders,
        c.avg_spent,
        c.max_item_price,
        c.min_item_price,
        RANK() OVER (ORDER BY c.total_net_profit DESC) AS rank
    FROM 
        CustomerSales c
)
SELECT 
    tc.customer_id,
    tc.total_net_profit,
    tc.total_orders,
    tc.avg_spent,
    tc.max_item_price,
    tc.min_item_price
FROM 
    TopCustomers tc
WHERE 
    tc.rank <= 10
ORDER BY 
    tc.total_net_profit DESC;
