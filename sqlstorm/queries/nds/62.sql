
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        customer AS c
    LEFT JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
high_value_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        DENSE_RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        customer_sales AS cs
    WHERE 
        cs.total_sales > 1000
),
date_filtered AS (
    SELECT 
        d.d_date_sk, 
        d.d_date, 
        d.d_month_seq 
    FROM 
        date_dim AS d 
    WHERE 
        d.d_year = 2023 AND d.d_month_seq IN (1, 2, 3)
)

SELECT 
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.total_sales,
    df.d_date,
    df.d_month_seq
FROM 
    high_value_customers AS hvc
JOIN 
    web_sales AS ws ON hvc.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    date_filtered AS df ON ws.ws_sold_date_sk = df.d_date_sk
WHERE 
    (hvc.sales_rank <= 50 OR hvc.total_sales IS NULL)
ORDER BY 
    hvc.total_sales DESC, df.d_date;
