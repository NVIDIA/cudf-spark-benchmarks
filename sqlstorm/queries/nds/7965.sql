
WITH annual_sales AS (
    SELECT 
        d.d_year,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year
), sales_by_gender AS (
    SELECT 
        cd.cd_gender,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender
), top_stores AS (
    SELECT 
        s.s_store_name,
        SUM(ss.ss_ext_sales_price) AS total_sales
    FROM 
        store s
    JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY 
        s.s_store_name
    ORDER BY 
        total_sales DESC
    LIMIT 5
)
SELECT 
    a.d_year,
    a.total_sales AS annual_web_sales,
    g.cd_gender,
    g.total_sales AS gender_sales,
    t.s_store_name,
    t.total_sales AS top_store_sales
FROM 
    annual_sales a
CROSS JOIN 
    sales_by_gender g
CROSS JOIN 
    top_stores t
ORDER BY 
    a.d_year, g.cd_gender, t.total_sales DESC;
