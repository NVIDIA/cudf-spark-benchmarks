
WITH CustomerSales AS (
  SELECT 
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    SUM(ws.ws_net_profit) AS total_profit,
    COUNT(ws.ws_order_number) AS total_orders
  FROM 
    customer c
  JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
  JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  WHERE 
    d.d_year = 2023
  GROUP BY 
    c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
  SELECT 
    c.c_customer_sk AS customer_sk,
    c.c_first_name AS first_name,
    c.c_last_name AS last_name,
    cs.total_profit,
    cs.total_orders,
    RANK() OVER (ORDER BY cs.total_profit DESC) AS profit_rank
  FROM 
    CustomerSales cs
  JOIN 
    customer c ON cs.c_customer_sk = c.c_customer_sk
)
SELECT 
  tc.first_name,
  tc.last_name,
  tc.total_profit,
  tc.total_orders
FROM 
  TopCustomers tc
WHERE 
  tc.profit_rank <= 10
ORDER BY 
  tc.total_profit DESC;
