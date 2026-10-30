
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_profit
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
        cs.total_profit,
        DENSE_RANK() OVER (ORDER BY cs.total_profit DESC) AS rank
    FROM 
        CustomerSales cs
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    COALESCE(tc.total_profit, 0) AS total_profit,
    COUNT(DISTINCT ws.ws_order_number) AS order_count,
    SUM(ws.ws_ext_discount_amt) AS total_discount,
    AVG(ws.ws_list_price) AS avg_item_price,
    SUM(CASE WHEN ws.ws_ship_mode_sk IS NULL THEN 1 ELSE 0 END) AS no_ship_mode_count
FROM 
    TopCustomers tc
LEFT JOIN 
    web_sales ws ON tc.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    tc.rank <= 10
GROUP BY 
    tc.c_customer_sk, tc.c_first_name, tc.c_last_name, tc.total_profit
ORDER BY 
    tc.total_profit DESC;
