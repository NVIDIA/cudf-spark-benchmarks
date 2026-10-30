
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2450000 AND 2450600
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_net_profit,
        RANK() OVER (ORDER BY cs.total_net_profit DESC) AS rank
    FROM 
        CustomerSales cs
    WHERE 
        cs.total_net_profit IS NOT NULL
),
WarehouseSales AS (
    SELECT 
        w.w_warehouse_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2450000 AND 2450600
    GROUP BY 
        w.w_warehouse_sk
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    wc.total_sales AS warehouse_sales,
    tc.total_net_profit,
    CASE 
        WHEN tc.rank <= 10 THEN 'Top 10 Customer'
        ELSE 'Other'
    END AS customer_category
FROM 
    TopCustomers tc
LEFT JOIN 
    WarehouseSales wc ON tc.c_customer_sk = (SELECT ws.ws_bill_customer_sk 
                                              FROM web_sales ws 
                                              WHERE ws.ws_warehouse_sk IN (SELECT w.w_warehouse_sk 
                                                                           FROM warehouse w))
WHERE 
    wc.total_sales IS NOT NULL
ORDER BY 
    tc.rank;
