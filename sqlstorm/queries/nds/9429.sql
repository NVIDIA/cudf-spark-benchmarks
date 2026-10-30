
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        ca.ca_city,
        cd.cd_gender,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cd.cd_gender = 'F'
        AND ws.ws_sold_date_sk BETWEEN 2459900 AND 2460565 
    GROUP BY 
        c.c_customer_id, ca.ca_city, cd.cd_gender
), RankedSales AS (
    SELECT 
        c.c_customer_id AS customer_id,
        ca.ca_city AS city,
        cd.cd_gender AS gender,
        cs.total_sales,
        cs.total_orders,
        DENSE_RANK() OVER (PARTITION BY ca.ca_city ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_id = c.c_customer_id
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    rs.city,
    COUNT(rs.customer_id) AS number_of_customers,
    AVG(rs.total_sales) AS avg_sales_per_customer
FROM 
    RankedSales rs
WHERE 
    rs.sales_rank <= 5
GROUP BY 
    rs.city
ORDER BY 
    avg_sales_per_customer DESC;
