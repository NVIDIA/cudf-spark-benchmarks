
WITH sales_summary AS (
    SELECT 
        w.w_warehouse_id,
        d.d_year,
        SUM(ss.ss_sales_price) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
        AVG(ss.ss_net_profit) AS avg_net_profit
    FROM 
        store_sales ss
    JOIN 
        date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN 
        warehouse w ON ss.ss_store_sk = w.w_warehouse_sk
    WHERE 
        d.d_year BETWEEN 2021 AND 2023
    GROUP BY 
        w.w_warehouse_id, d.d_year
),
customer_summary AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d.d_date_sk FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
)
SELECT 
    ss.w_warehouse_id,
    ss.d_year,
    ss.total_sales,
    ss.total_transactions,
    ss.avg_net_profit,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.customer_count,
    cs.total_spent
FROM 
    sales_summary ss
JOIN 
    customer_summary cs ON ss.d_year = 2023
ORDER BY 
    ss.total_sales DESC, cs.total_spent DESC
LIMIT 10;
