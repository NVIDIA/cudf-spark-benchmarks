
WITH customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_current_cdemo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        SUM(ss.ss_net_paid_inc_tax) AS total_sales,
        COUNT(ss.ss_ticket_number) AS total_transactions
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_current_cdemo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating
),
income_distribution AS (
    SELECT 
        hd.hd_income_band_sk, 
        COUNT(*) AS customer_count
    FROM 
        household_demographics hd
    JOIN 
        customer c ON hd.hd_demo_sk = c.c_current_hdemo_sk
    GROUP BY 
        hd.hd_income_band_sk
),
sales_by_time AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year, d.d_month_seq
),
highest_sales AS (
    SELECT 
        c.c_customer_id, 
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        ws.ws_net_profit IS NOT NULL
    GROUP BY 
        c.c_customer_id
    HAVING 
        SUM(ws.ws_net_profit) > 1000 
),
final_report AS (
    SELECT 
        cs.c_customer_sk,
        cs.cd_gender,
        cs.cd_marital_status,
        cs.total_sales,
        cs.total_transactions,
        id.customer_count AS income_band_count,
        st.total_profit AS year_profit
    FROM 
        customer_summary cs
    LEFT JOIN 
        income_distribution id ON cs.c_current_cdemo_sk = id.hd_income_band_sk
    LEFT JOIN 
        sales_by_time st ON st.d_year = EXTRACT(YEAR FROM CAST('2002-10-01' AS DATE))
    WHERE 
        cs.total_sales > 500
)
SELECT 
    fr.c_customer_sk,
    fr.cd_gender,
    fr.cd_marital_status,
    fr.total_sales,
    fr.total_transactions,
    COALESCE(fr.income_band_count, 0) AS income_band_count,
    COALESCE(fr.year_profit, 0.00) AS year_profit
FROM 
    final_report fr
ORDER BY 
    fr.total_sales DESC
LIMIT 100;
