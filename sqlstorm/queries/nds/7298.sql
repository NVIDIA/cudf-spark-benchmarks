
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year >= 1980 AND c.c_birth_year <= 2000
    GROUP BY 
        c.c_customer_id
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        c.total_sales,
        c.total_orders,
        c.avg_net_profit,
        DENSE_RANK() OVER (ORDER BY c.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales c
)
SELECT 
    tu.c_customer_id AS customer_id,
    tu.total_sales AS total_sales,
    tu.total_orders AS total_orders,
    tu.avg_net_profit AS avg_net_profit
FROM 
    TopCustomers tu
WHERE 
    tu.sales_rank <= 10
ORDER BY 
    tu.total_sales DESC;
