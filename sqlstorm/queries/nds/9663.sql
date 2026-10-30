
WITH CustomerStats AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status
),
StoreStats AS (
    SELECT 
        s.s_store_id,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
        SUM(ss.ss_sales_price) AS total_revenue,
        AVG(ss.ss_net_profit) AS avg_net_profit
    FROM 
        store s
    JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    JOIN 
        date_dim dd ON ss.ss_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        s.s_store_id
)
SELECT 
    cs.c_customer_id,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.total_quantity,
    cs.total_sales,
    cs.avg_profit,
    ss.s_store_id,
    ss.total_transactions,
    ss.total_revenue,
    ss.avg_net_profit
FROM 
    CustomerStats cs
JOIN 
    StoreStats ss ON cs.total_sales = ss.total_revenue
ORDER BY 
    cs.total_sales DESC, ss.total_revenue DESC
LIMIT 100;
