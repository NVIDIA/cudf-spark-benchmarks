
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        COUNT(DISTINCT ws.ws_web_page_sk) AS unique_page_visits
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
RankedSales AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        cs.order_count,
        cs.unique_page_visits,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
),
TopSales AS (
    SELECT 
        r.c_customer_sk,
        r.c_first_name,
        r.c_last_name,
        r.total_sales,
        r.order_count,
        r.unique_page_visits
    FROM 
        RankedSales r
    WHERE 
        r.sales_rank <= 10
)
SELECT 
    ts.c_customer_sk,
    ts.c_first_name || ' ' || ts.c_last_name AS full_name,
    ts.total_sales,
    ts.order_count,
    COALESCE(ts.unique_page_visits, 0) AS unique_visits,
    CASE 
        WHEN ts.total_sales > 10000 THEN 'High'
        WHEN ts.total_sales > 5000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category
FROM 
    TopSales ts
LEFT JOIN 
    customer_demographics cd ON ts.c_customer_sk = cd.cd_demo_sk
WHERE 
    cd.cd_credit_rating IS NOT NULL
ORDER BY 
    ts.total_sales DESC;
