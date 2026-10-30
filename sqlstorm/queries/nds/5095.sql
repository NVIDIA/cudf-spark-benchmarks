
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS total_orders
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2451905 AND 2451950
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_profit,
        cs.total_orders,
        RANK() OVER (ORDER BY cs.total_profit DESC) AS profit_rank
    FROM CustomerSales cs
),
SalesByDemographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        AVG(ts.total_profit) AS avg_profit,
        AVG(ts.total_orders) AS avg_orders
    FROM TopCustomers ts
    JOIN customer_demographics cd ON ts.c_customer_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender, cd.cd_marital_status
)

SELECT 
    sb.cd_gender,
    sb.cd_marital_status,
    sb.avg_profit,
    sb.avg_orders,
    COUNT(*) AS demographics_count
FROM SalesByDemographics sb
JOIN (SELECT DISTINCT cd_gender, cd_marital_status FROM customer_demographics) d ON 1=1
GROUP BY sb.cd_gender, sb.cd_marital_status, sb.avg_profit, sb.avg_orders
HAVING COUNT(*) > 10
ORDER BY sb.avg_profit DESC;
