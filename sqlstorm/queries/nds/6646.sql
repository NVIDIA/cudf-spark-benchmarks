WITH CustomerStats AS (
    SELECT 
        cd.cd_gender,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_revenue,
        COUNT(DISTINCT c.c_customer_sk) AS unique_customers
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2001
    GROUP BY 
        cd.cd_gender
),
StoreStats AS (
    SELECT 
        s.s_store_id,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit
    FROM 
        store s
    JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    WHERE 
        ss.ss_sold_date_sk BETWEEN 20230101 AND 20231231
    GROUP BY 
        s.s_store_id
),
CombinedStats AS (
    SELECT 
        cs.cd_gender,
        ss.total_sales,
        ss.total_profit,
        cs.total_quantity,
        cs.total_revenue,
        cs.unique_customers
    FROM 
        CustomerStats cs
    LEFT JOIN 
        StoreStats ss ON cs.cd_gender = (CASE WHEN cs.cd_gender = 'M' THEN 'Male' ELSE 'Female' END)  
)
SELECT 
    cd_gender,
    total_sales,
    total_profit,
    total_quantity,
    total_revenue,
    unique_customers
FROM 
    CombinedStats
ORDER BY 
    total_revenue DESC, total_quantity DESC;