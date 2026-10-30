
WITH SalesData AS (
    SELECT 
        c.c_customer_id,
        ca.ca_city,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        wd.web_site_id,
        d.d_year,
        d.d_month_seq
    FROM 
        web_sales AS ws
    JOIN 
        customer AS c ON ws.ws_ship_customer_sk = c.c_customer_sk
    JOIN 
        customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        web_site AS wd ON ws.ws_web_site_sk = wd.web_site_sk
    JOIN 
        date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023 
        AND d.d_month_seq BETWEEN 1 AND 12
    GROUP BY 
        c.c_customer_id, ca.ca_city, wd.web_site_id, d.d_year, d.d_month_seq
),
RankedSales AS (
    SELECT 
        city,
        web_site_id,
        total_sales,
        order_count,
        ROW_NUMBER() OVER (PARTITION BY city ORDER BY total_sales DESC) AS sales_rank
    FROM 
        (SELECT 
            ca_city AS city,
            web_site_id,
            SUM(total_sales) AS total_sales,
            SUM(order_count) AS order_count
         FROM 
            SalesData
         GROUP BY 
            ca_city, web_site_id) AS city_sales
)
SELECT 
    city,
    web_site_id,
    total_sales,
    order_count
FROM 
    RankedSales
WHERE 
    sales_rank <= 5
ORDER BY 
    city, total_sales DESC;
