
WITH RankedAddresses AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        COUNT(c.c_customer_sk) AS customer_count,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_city ORDER BY COUNT(c.c_customer_sk) DESC) AS city_rank
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY 
        ca.ca_address_sk, ca.ca_city, ca.ca_state
),
TopCities AS (
    SELECT 
        ca_city,
        ca_state,
        customer_count
    FROM 
        RankedAddresses
    WHERE 
        city_rank <= 5
),
SalesData AS (
    SELECT 
        d.d_year,
        SUM(ws.ws_net_paid) AS total_sales,
        SUM(ws.ws_quantity) AS total_quantity
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year
)
SELECT 
    tc.ca_city,
    tc.ca_state,
    sd.d_year,
    sd.total_sales,
    sd.total_quantity,
    CONCAT(tc.ca_city, ', ', tc.ca_state) AS city_state
FROM 
    TopCities tc
JOIN 
    SalesData sd ON sd.d_year IN (2020, 2021, 2022)
ORDER BY 
    sd.total_sales DESC, 
    tc.ca_city, 
    tc.ca_state;
