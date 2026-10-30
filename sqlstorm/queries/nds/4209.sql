
WITH RankedSales AS (
    SELECT 
        c.c_customer_sk,
        ca.ca_city,
        d.d_year,
        SUM(ws.ws_net_profit) AS total_net_profit,
        RANK() OVER (PARTITION BY d.d_year ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year IN (2021, 2022)
    GROUP BY 
        c.c_customer_sk, ca.ca_city, d.d_year
),
TopCities AS (
    SELECT 
        ca.ca_city,
        d.d_year,
        SUM(ws.ws_net_profit) AS city_net_profit
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        ca.ca_city, d.d_year
    HAVING 
        SUM(ws.ws_net_profit) > (
            SELECT AVG(total_net_profit) 
            FROM RankedSales rs 
            WHERE rs.d_year = d.d_year
        )
)
SELECT 
    rc.c_customer_sk,
    rc.ca_city,
    rc.d_year,
    rc.total_net_profit
FROM 
    RankedSales rc
JOIN 
    TopCities tc ON rc.ca_city = tc.ca_city AND rc.d_year = tc.d_year
WHERE 
    rc.profit_rank <= 5
ORDER BY 
    rc.d_year, rc.total_net_profit DESC;
