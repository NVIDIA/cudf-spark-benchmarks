
WITH SalesSummary AS (
    SELECT 
        c.c_customer_id, 
        ca.ca_city,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2022
    GROUP BY c.c_customer_id, ca.ca_city
),
TopCities AS (
    SELECT 
        ca.ca_city, 
        SUM(total_sales) AS city_sales
    FROM SalesSummary
    JOIN customer_address ca ON SalesSummary.ca_city = ca.ca_city
    GROUP BY ca.ca_city
    ORDER BY city_sales DESC
    LIMIT 5
)
SELECT 
    ss.c_customer_id,
    ss.total_quantity,
    ss.total_sales,
    ss.order_count,
    tc.city_sales
FROM SalesSummary ss
JOIN TopCities tc ON ss.ca_city = tc.ca_city
ORDER BY ss.total_sales DESC;
