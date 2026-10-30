
WITH customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount,
        AVG(sr_return_tax) AS average_return_tax
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
top_customers AS (
    SELECT 
        c.c_customer_sk,
        RANK() OVER (ORDER BY total_return_amount DESC) AS rank_by_return
    FROM 
        customer_summary c
    WHERE 
        total_returns > 0
),
monthly_sales AS (
    SELECT 
        dd.d_year,
        dd.d_month_seq,
        SUM(ws_ext_sales_price) AS monthly_sales
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    GROUP BY 
        dd.d_year, dd.d_month_seq
),
return_percentage AS (
    SELECT 
        m.d_year,
        m.d_month_seq,
        COALESCE(SUM(CASE WHEN r.total_returns IS NOT NULL THEN r.total_return_amount ELSE 0 END), 0) AS total_returns,
        m.monthly_sales,
        CASE 
            WHEN m.monthly_sales = 0 THEN 0 
            ELSE ROUND((COALESCE(SUM(CASE WHEN r.total_returns IS NOT NULL THEN r.total_return_amount ELSE 0 END), 0) / m.monthly_sales) * 100, 2) 
        END AS return_percentage
    FROM 
        monthly_sales m
    LEFT JOIN 
        customer_summary r ON m.d_year = r.total_returns
    GROUP BY 
        m.d_year, m.d_month_seq, m.monthly_sales
)
SELECT 
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    r.return_percentage,
    CASE 
        WHEN r.return_percentage > 20 THEN 'High Risk'
        WHEN r.return_percentage BETWEEN 10 AND 20 THEN 'Moderate Risk'
        ELSE 'Low Risk'
    END AS risk_category
FROM 
    customer_summary c
JOIN 
    return_percentage r ON c.c_customer_sk = r.d_month_seq
WHERE 
    r.return_percentage IS NOT NULL
ORDER BY 
    r.return_percentage DESC
LIMIT 10;
