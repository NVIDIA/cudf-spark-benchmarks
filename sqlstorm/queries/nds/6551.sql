
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_ship_mode_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws 
    JOIN 
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.ws_order_number, ws.ws_ship_mode_sk
),
CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_profit) AS total_spent
    FROM 
        customer c 
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 20230101 AND 20231231
    GROUP BY 
        c.c_customer_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        COUNT(DISTINCT cs.c_customer_sk) AS customer_count,
        SUM(cs.total_spent) AS total_revenue
    FROM 
        customer_demographics cd
    JOIN 
        CustomerSales cs ON cd.cd_demo_sk = cs.c_customer_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender
)
SELECT 
    cd.cd_gender,
    COUNT(DISTINCT cd.cd_demo_sk) AS gender_count,
    SUM(cd.total_revenue) AS overall_revenue,
    AVG(cs.order_count) AS avg_orders_per_customer
FROM 
    CustomerDemographics cd
JOIN 
    CustomerSales cs ON cd.cd_demo_sk = cs.c_customer_sk
GROUP BY 
    cd.cd_gender
ORDER BY 
    overall_revenue DESC
LIMIT 10;
