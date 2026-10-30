
WITH customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.d_year,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        c.c_first_shipto_date_sk IS NOT NULL
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, d.d_year, cd.cd_gender, cd.cd_marital_status
),
top_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_quantity,
        cs.total_sales,
        ROW_NUMBER() OVER (PARTITION BY cs.d_year ORDER BY cs.total_sales DESC) AS rank,
        cs.d_year
    FROM 
        customer_summary cs
)
SELECT 
    t.c_first_name,
    t.c_last_name,
    t.total_quantity,
    t.total_sales,
    t.d_year
FROM 
    top_customers t
WHERE 
    t.rank <= 10
ORDER BY 
    t.d_year, t.total_sales DESC;
