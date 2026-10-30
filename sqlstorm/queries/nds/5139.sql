
WITH sales_summary AS (
    SELECT 
        wd.d_year,
        wd.d_month_seq,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim wd ON ws.ws_sold_date_sk = wd.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        wd.d_year BETWEEN 2019 AND 2023
    GROUP BY 
        wd.d_year, wd.d_month_seq, cd.cd_gender, cd.cd_marital_status
),
monthly_performance AS (
    SELECT 
        d_year,
        d_month_seq,
        cd_gender,
        cd_marital_status,
        total_quantity,
        total_net_profit,
        RANK() OVER (PARTITION BY d_year, cd_gender ORDER BY total_net_profit DESC) AS rank_by_profits
    FROM 
        sales_summary
)
SELECT 
    d_year,
    d_month_seq,
    cd_gender,
    cd_marital_status,
    total_quantity,
    total_net_profit,
    rank_by_profits
FROM 
    monthly_performance
WHERE 
    rank_by_profits <= 3
ORDER BY 
    d_year, cd_gender, rank_by_profits;
