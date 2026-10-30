
WITH  revenue_summary AS (
    SELECT 
        d.d_year, 
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    WHERE 
        d.d_year BETWEEN 2018 AND 2023
    GROUP BY 
        d.d_year
    UNION ALL
    SELECT 
        d.d_year, 
        SUM(cs.cs_ext_sales_price) AS total_sales
    FROM 
        date_dim d
    JOIN 
        catalog_sales cs ON d.d_date_sk = cs.cs_sold_date_sk
    WHERE 
        d.d_year BETWEEN 2018 AND 2023
    GROUP BY 
        d.d_year
), customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_email_address,
        cd.cd_gender,
        SUM(ws.ws_net_paid) AS total_net_paid,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_email_address, cd.cd_gender
),
top_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_email_address,
        cs.cd_gender,
        cs.total_net_paid,
        cs.order_count,
        ROW_NUMBER() OVER (PARTITION BY cs.cd_gender ORDER BY cs.total_net_paid DESC) AS rn
    FROM 
        customer_summary cs
)
SELECT 
    rs.d_year,
    COALESCE(tc.cd_gender, 'Unknown') AS cd_gender,
    COUNT(tc.c_customer_sk) AS customer_count,
    SUM(tc.total_net_paid) AS total_revenue
FROM 
    revenue_summary rs
LEFT JOIN 
    top_customers tc ON rs.d_year = (SELECT MAX(d_year) FROM revenue_summary)
WHERE 
    tc.rn <= 10
GROUP BY 
    rs.d_year, tc.cd_gender
ORDER BY 
    rs.d_year, total_revenue DESC;
