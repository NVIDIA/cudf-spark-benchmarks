
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_net_profit,
        MAX(ws.ws_sold_date_sk) AS last_order_date
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
HighValueCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_orders,
        cs.total_net_profit,
        cs.last_order_date,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        CustomerSales cs
    JOIN 
        customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
    WHERE 
        cs.total_net_profit > (SELECT AVG(total_net_profit) FROM CustomerSales)
),
RecentUtils AS (
    SELECT 
        cs.c_customer_sk,
        ws.ws_ship_mode_sk,
        COUNT(ws.ws_order_number) AS total_recent_orders,
        SUM(ws.ws_net_profit) AS recent_sales_profit
    FROM 
        CustomerSales cs
    JOIN 
        web_sales ws ON cs.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk > (SELECT MAX(last_order_date) - 30 FROM HighValueCustomers)
    GROUP BY 
        cs.c_customer_sk, ws.ws_ship_mode_sk
)
SELECT 
    hvc.c_customer_sk,
    hvc.total_orders,
    hvc.total_net_profit,
    hvc.last_order_date,
    ru.ws_ship_mode_sk,
    ru.total_recent_orders,
    ru.recent_sales_profit
FROM 
    HighValueCustomers hvc
LEFT JOIN 
    RecentUtils ru ON hvc.c_customer_sk = ru.c_customer_sk
ORDER BY 
    hvc.total_net_profit DESC, ru.recent_sales_profit DESC
LIMIT 100;
