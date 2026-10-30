
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS rn,
        i.i_brand
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (
            SELECT MAX(d_date_sk) 
            FROM date_dim 
            WHERE d_year = 2022) - 90 
        AND 
        (SELECT MAX(d_date_sk) 
         FROM date_dim 
         WHERE d_year = 2022)
),
TopSelling AS (
    SELECT 
        rs.ws_item_sk,
        rs.ws_order_number,
        SUM(rs.ws_sales_price) AS total_sales,
        COUNT(rs.ws_order_number) AS order_count
    FROM 
        RankedSales rs
    WHERE 
        rs.rn <= 5
    GROUP BY 
        rs.ws_item_sk, rs.ws_order_number
)
SELECT 
    ca.ca_city,
    COUNT(DISTINCT ts.ws_order_number) AS total_orders,
    SUM(ts.total_sales) AS total_revenue,
    AVG(ts.total_sales) AS avg_order_value
FROM 
    TopSelling ts
LEFT JOIN 
    customer c ON c.c_customer_sk = ts.ws_order_number
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    date_dim d ON ts.ws_order_number = d.d_date_sk
WHERE 
    ca.ca_city IS NOT NULL
GROUP BY 
    ca.ca_city
HAVING 
    SUM(ts.total_sales) > 1000
ORDER BY 
    total_revenue DESC
LIMIT 10;
