
WITH CustomerPurchases AS (
    SELECT 
        c.c_customer_sk,
        ca.ca_city,
        cd.cd_gender,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer c
        JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
        JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cd.cd_gender = 'F'
        AND ca.ca_state = 'NY'
        AND ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
                                    AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        c.c_customer_sk, ca.ca_city, cd.cd_gender
),
RankedSales AS (
    SELECT 
        cp.c_customer_sk,
        cp.ca_city,
        cp.cd_gender,
        cp.total_sales,
        cp.total_orders,
        RANK() OVER (PARTITION BY cp.ca_city ORDER BY cp.total_sales DESC) as sales_rank
    FROM 
        CustomerPurchases cp
)
SELECT 
    rs.ca_city,
    AVG(rs.total_sales) AS avg_sales,
    MAX(rs.total_orders) AS max_orders,
    COALESCE(MAX(CASE WHEN rs.sales_rank = 1 THEN rs.total_sales END), 0) AS city_top_sales,
    COUNT(DISTINCT rs.c_customer_sk) AS unique_customers
FROM 
    RankedSales rs
GROUP BY 
    rs.ca_city
HAVING 
    COUNT(DISTINCT rs.c_customer_sk) > 5
ORDER BY 
    avg_sales DESC
LIMIT 10;
