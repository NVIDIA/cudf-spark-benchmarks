
WITH AddressInfo AS (
    SELECT 
        c.c_customer_id,
        COALESCE(NULLIF(c.c_first_name, ''), 'N/A') AS first_name,
        COALESCE(NULLIF(c.c_last_name, ''), 'N/A') AS last_name,
        CONCAT_WS(', ', 
            COALESCE(NULLIF(a.ca_street_number, ''), 'N/A'),
            COALESCE(NULLIF(a.ca_street_name, ''), 'N/A'),
            COALESCE(NULLIF(a.ca_city, ''), 'N/A'),
            COALESCE(NULLIF(a.ca_state, ''), 'N/A'),
            COALESCE(NULLIF(a.ca_zip, ''), 'N/A'),
            COALESCE(NULLIF(a.ca_country, ''), 'N/A')
        ) AS full_address
    FROM 
        customer c
    JOIN 
        customer_address a ON c.c_current_addr_sk = a.ca_address_sk
),
SalesData AS (
    SELECT 
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        EXTRACT(YEAR FROM d.d_date) AS sales_year,
        EXTRACT(MONTH FROM d.d_date) AS sales_month
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_date BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY 
        EXTRACT(YEAR FROM d.d_date), EXTRACT(MONTH FROM d.d_date)
)
SELECT 
    a.c_customer_id,
    a.first_name,
    a.last_name,
    a.full_address,
    COALESCE(sd.total_sales, 0) AS total_sales,
    COALESCE(sd.order_count, 0) AS order_count
FROM 
    AddressInfo a
LEFT JOIN 
    SalesData sd ON 1 = 1
ORDER BY 
    a.c_customer_id;
