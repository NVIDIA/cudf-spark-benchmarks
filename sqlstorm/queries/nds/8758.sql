
WITH SalesData AS (
    SELECT 
        ws.ws_web_page_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_net_paid,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE 
        dd.d_year = 2023 AND 
        dd.d_month_seq BETWEEN 1 AND 12 
    GROUP BY 
        ws.ws_web_page_sk
), 
CustomerData AS (
    SELECT 
        wi.wp_web_page_sk,
        COUNT(DISTINCT c.c_customer_sk) AS total_customers
    FROM 
        web_page wi
    JOIN 
        web_sales ws ON wi.wp_web_page_sk = ws.ws_web_page_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_preferred_cust_flag = 'Y'
    GROUP BY 
        wi.wp_web_page_sk
)
SELECT 
    s.wp_web_page_sk,
    sd.total_quantity,
    sd.total_net_paid,
    cd.total_customers
FROM 
    SalesData sd
LEFT JOIN 
    CustomerData cd ON sd.ws_web_page_sk = cd.wp_web_page_sk
JOIN 
    web_page s ON sd.ws_web_page_sk = s.wp_web_page_sk
ORDER BY 
    sd.total_net_paid DESC
LIMIT 10;
