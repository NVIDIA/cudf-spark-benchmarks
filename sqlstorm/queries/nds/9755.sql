
WITH SalesSummary AS (
    SELECT 
        c.c_customer_sk,
        ca.ca_city,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_ship_mode_sk) AS distinct_shipping_methods,
        AVG(ws.ws_net_paid_inc_tax) AS avg_payment,
        d.d_year
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
        AND ca.ca_state = 'CA'
    GROUP BY 
        c.c_customer_sk, ca.ca_city, d.d_year
), Ranks AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY ca_city ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SalesSummary
)
SELECT 
    r.c_customer_sk,
    r.ca_city,
    r.total_sales,
    r.total_orders,
    r.distinct_shipping_methods,
    r.avg_payment,
    r.sales_rank
FROM 
    Ranks r
WHERE 
    r.sales_rank <= 10
ORDER BY 
    r.ca_city, r.sales_rank;
