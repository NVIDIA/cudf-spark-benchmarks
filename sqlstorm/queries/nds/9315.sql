
WITH sales_summary AS (
    SELECT 
        c.c_customer_id AS customer_id,
        ca.ca_city AS ca_city,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        COUNT(CASE WHEN p.p_promo_sk IS NOT NULL THEN 1 END) AS promo_used_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        c.c_customer_id, ca.ca_city
),
ranked_sales AS (
    SELECT 
        customer_id,
        ca_city,
        total_sales,
        order_count,
        avg_sales_price,
        promo_used_count,
        RANK() OVER (PARTITION BY ca_city ORDER BY total_sales DESC) AS city_rank
    FROM 
        sales_summary
)
SELECT 
    customer_id,
    ca_city,
    total_sales,
    order_count,
    avg_sales_price,
    promo_used_count
FROM 
    ranked_sales
WHERE 
    city_rank <= 10
ORDER BY 
    ca_city, total_sales DESC;
