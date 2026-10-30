
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        SUM(ws.ws_net_profit) AS total_profit
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 
                                  AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
ProfitRanked AS (
    SELECT 
        cs.c_customer_sk AS customer_sk, 
        cs.c_first_name AS first_name, 
        cs.c_last_name AS last_name, 
        cs.total_profit,
        RANK() OVER (ORDER BY cs.total_profit DESC) AS profit_rank
    FROM CustomerSales cs
),
TopCustomers AS (
    SELECT 
        customer_sk, 
        first_name, 
        last_name, 
        total_profit
    FROM ProfitRanked 
    WHERE profit_rank <= 10
),
WarehouseSales AS (
    SELECT 
        w.w_warehouse_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM warehouse w
    JOIN web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY w.w_warehouse_sk
)

SELECT 
    tc.first_name,
    tc.last_name,
    tc.total_profit,
    ws.total_sales
FROM TopCustomers tc
JOIN WarehouseSales ws ON tc.customer_sk = ws.w_warehouse_sk
ORDER BY tc.total_profit DESC, ws.total_sales DESC;
