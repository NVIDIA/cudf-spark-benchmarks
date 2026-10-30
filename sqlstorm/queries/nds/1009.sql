
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_net_profit DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 1000 AND 2000
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(hd.hd_buy_potential, 'Unknown') AS hd_buy_potential
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
),
SalesSummary AS (
    SELECT 
        ci.c_customer_sk,
        COUNT(DISTINCT rs.ws_order_number) AS total_orders,
        SUM(rs.ws_net_profit) AS total_profit,
        AVG(rs.ws_sales_price) AS avg_sales_price
    FROM 
        RankedSales rs
    JOIN 
        CustomerInfo ci ON rs.ws_item_sk = ci.c_customer_sk
    GROUP BY 
        ci.c_customer_sk
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ss.total_orders,
        ss.total_profit,
        ss.avg_sales_price
    FROM 
        CustomerInfo c
    JOIN 
        SalesSummary ss ON c.c_customer_sk = ss.c_customer_sk
    WHERE 
        ss.total_profit > (SELECT AVG(total_profit) FROM SalesSummary)
)
SELECT 
    hvc.c_customer_sk,
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.total_orders,
    hvc.total_profit,
    hvc.avg_sales_price,
    CASE 
        WHEN hvc.total_orders > 10 THEN 'High Activity'
        WHEN hvc.total_orders BETWEEN 5 AND 10 THEN 'Moderate Activity'
        ELSE 'Low Activity'
    END AS activity_level
FROM 
    HighValueCustomers hvc
ORDER BY 
    hvc.total_profit DESC
LIMIT 50;
