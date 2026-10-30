WITH SalesData AS (
    SELECT 
        ws_sold_date_sk,
        ws_web_site_sk,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        SUM(ws_quantity) AS total_quantity
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2458477 AND 2458531 
    GROUP BY 
        ws_sold_date_sk, ws_web_site_sk
),
TopSites AS (
    SELECT 
        ws_web_site_sk,
        total_sales,
        ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS rank
    FROM 
        SalesData
),
CustomerAddress AS (
    SELECT 
        ca_address_sk,
        ca_city,
        ca_state
    FROM 
        customer_address
    WHERE 
        ca_state IN ('CA', 'NY') 
),
SalesOverTime AS (
    SELECT 
        d_year,
        d_month_seq,
        SUM(ws_ext_sales_price) AS monthly_sales
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    GROUP BY 
        d_year, d_month_seq
),
Comparison AS (
    SELECT 
        T1.d_year,
        T1.d_month_seq,
        T1.monthly_sales AS current_sales,
        COALESCE(T2.monthly_sales, 0) AS previous_sales,
        T1.monthly_sales - COALESCE(T2.monthly_sales, 0) AS sales_diff
    FROM 
        SalesOverTime T1
    LEFT JOIN 
        SalesOverTime T2 ON T1.d_year = T2.d_year + 1 AND T1.d_month_seq = T2.d_month_seq
)
SELECT 
    cs.c_customer_id,
    cs.c_first_name,
    cs.c_last_name,
    ca.ca_city,
    ca.ca_state,
    t.total_sales,
    c.sales_diff
FROM 
    customer AS cs
LEFT JOIN 
    customer_address AS ca ON cs.c_current_addr_sk = ca.ca_address_sk
JOIN 
    TopSites AS t ON cs.c_customer_sk = t.ws_web_site_sk
JOIN 
    Comparison AS c ON EXTRACT(MONTH FROM cast('2002-10-01' as date)) = c.d_month_seq
WHERE 
    (cs.c_preferred_cust_flag = 'Y' OR cs.c_birth_year < 1980)
    AND t.rank <= 5
ORDER BY 
    t.total_sales DESC, cs.c_last_name;