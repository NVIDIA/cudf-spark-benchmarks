
WITH customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(DISTINCT sr.sr_item_sk) AS total_returns,
        SUM(sr.sr_return_amt) AS total_return_amount,
        SUM(sr.sr_return_quantity) AS total_return_quantity
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
monthly_sales AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        SUM(ws.ws_ext_sales_price) AS monthly_sales
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year, d.d_month_seq
),
customer_best_return AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_returns,
        cs.total_return_amount,
        ROW_NUMBER() OVER (PARTITION BY cs.c_customer_sk ORDER BY cs.total_return_amount DESC) AS rank
    FROM 
        customer_summary cs
    WHERE 
        cs.total_returns > 0
)
SELECT 
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    cs.total_returns,
    cs.total_return_amount,
    ms.monthly_sales,
    cb.rank
FROM 
    customer_summary cs
JOIN 
    monthly_sales ms ON EXTRACT(YEAR FROM DATE '2002-10-01') = ms.d_year
LEFT JOIN 
    customer_best_return cb ON cs.c_customer_sk = cb.c_customer_sk AND cb.rank = 1
WHERE 
    cs.total_returns > 0
ORDER BY 
    cs.total_return_amount DESC
LIMIT 10;
