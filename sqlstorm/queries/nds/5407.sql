
WITH SalesData AS (
    SELECT 
        ws.ws_web_site_sk,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_quantity) AS avg_quantity,
        EXTRACT(DAY FROM d.d_date) AS sale_day,
        EXTRACT(MONTH FROM d.d_date) AS sale_month,
        EXTRACT(YEAR FROM d.d_date) AS sale_year
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        ws.ws_web_site_sk, 
        EXTRACT(DAY FROM d.d_date),
        EXTRACT(MONTH FROM d.d_date),
        EXTRACT(YEAR FROM d.d_date)
),
CustomerAnalytics AS (
    SELECT 
        ca.ca_city,
        d.d_year,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        SUM(s.total_sales) AS total_sales_by_city
    FROM 
        SalesData s
    JOIN 
        customer c ON c.c_current_addr_sk = s.ws_web_site_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        date_dim d ON s.sale_day = EXTRACT(DAY FROM d.d_date) 
                     AND s.sale_month = EXTRACT(MONTH FROM d.d_date) 
                     AND s.sale_year = d.d_year
    GROUP BY 
        ca.ca_city,
        d.d_year
)
SELECT 
    ca.ca_city,
    ca.d_year,
    ca.customer_count,
    ca.total_sales_by_city,
    CASE 
        WHEN ca.total_sales_by_city > 100000 THEN 'High'
        WHEN ca.total_sales_by_city BETWEEN 50000 AND 100000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category
FROM 
    CustomerAnalytics ca
ORDER BY 
    ca.total_sales_by_city DESC;
