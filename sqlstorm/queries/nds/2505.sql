
WITH customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        SUM(COALESCE(ws.ws_quantity, 0)) AS total_quantity,
        SUM(COALESCE(ws.ws_sales_price, 0)) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY cd.cd_credit_rating ORDER BY SUM(COALESCE(ws.ws_sales_price, 0)) DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating
),
monthly_sales AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        SUM(ws.ws_sales_price) AS monthly_sales
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year, d.d_month_seq
),
top_months AS (
    SELECT 
        d_year, 
        d_month_seq,
        monthly_sales,
        RANK() OVER (ORDER BY monthly_sales DESC) AS month_rank
    FROM 
        monthly_sales
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.total_quantity,
    cs.total_sales,
    tm.d_year,
    tm.d_month_seq,
    tm.monthly_sales
FROM 
    customer_summary cs
JOIN 
    top_months tm ON cs.total_sales > (SELECT AVG(monthly_sales) FROM monthly_sales) 
WHERE 
    cs.sales_rank <= 10 
ORDER BY 
    cs.total_sales DESC, 
    tm.monthly_sales DESC;
