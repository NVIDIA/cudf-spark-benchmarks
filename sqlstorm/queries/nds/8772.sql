
WITH RankedSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        customer AS c
    JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim AS d ON d.d_date_sk = ws.ws_sold_date_sk
    JOIN 
        web_site AS w ON w.web_site_sk = ws.ws_web_site_sk
    WHERE 
        d.d_year = 2023 
        AND w.web_class = 'Retail'
    GROUP BY 
        c.c_customer_id, cd.cd_gender
),
TopSales AS (
    SELECT 
        sales_rank,
        c_customer_id,
        total_sales,
        order_count
    FROM 
        RankedSales
    WHERE 
        sales_rank <= 10
)
SELECT 
    t.sales_rank,
    t.c_customer_id,
    t.total_sales,
    t.order_count,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    ca.ca_city,
    ca.ca_state
FROM 
    TopSales AS t
JOIN 
    customer AS c ON c.c_customer_id = t.c_customer_id
JOIN 
    customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
ORDER BY 
    total_sales DESC;
