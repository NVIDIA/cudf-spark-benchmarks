
WITH sales_summary AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        s.s_store_id,
        SUM(ss.ss_sold_date_sk) AS total_sales,
        SUM(ss.ss_sales_price) AS total_revenue,
        AVG(ss.ss_net_profit) AS avg_net_profit
    FROM 
        store_sales ss
    JOIN 
        date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN 
        store s ON ss.ss_store_sk = s.s_store_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2023
    GROUP BY 
        d.d_year, d.d_month_seq, s.s_store_id
),
customer_summary AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status
),
combine_summary AS (
    SELECT 
        ss.d_year,
        ss.d_month_seq,
        ss.s_store_id,
        cs.cd_gender,
        cs.cd_marital_status,
        SUM(cs.total_spent) AS total_customer_spending,
        SUM(ss.total_revenue) AS store_revenue,
        AVG(ss.avg_net_profit) AS avg_store_profit
    FROM 
        sales_summary ss
    JOIN 
        customer_summary cs ON ss.total_sales > 1000
    GROUP BY 
        ss.d_year, ss.d_month_seq, ss.s_store_id, cs.cd_gender, cs.cd_marital_status
)
SELECT 
    d_year,
    d_month_seq,
    s_store_id,
    cd_gender,
    cd_marital_status,
    total_customer_spending,
    store_revenue,
    avg_store_profit
FROM 
    combine_summary
ORDER BY 
    d_year, d_month_seq, s_store_id;
