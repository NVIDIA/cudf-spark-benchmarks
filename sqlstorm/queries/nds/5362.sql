
WITH SalesData AS (
    SELECT 
        c.c_customer_id,
        ca.ca_city,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_profit
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE 
        d.d_year = 2023 
        AND p.p_discount_active = 'Y'
    GROUP BY 
        c.c_customer_id, ca.ca_city
),
RankedSales AS (
    SELECT 
        c_customer_id,
        ca_city,
        total_orders,
        total_sales,
        avg_profit,
        RANK() OVER (PARTITION BY ca_city ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SalesData
)
SELECT 
    ca_city,
    COUNT(c_customer_id) AS num_customers,
    SUM(total_orders) AS total_orders,
    SUM(total_sales) AS total_revenue,
    AVG(avg_profit) AS avg_profit_per_customer
FROM 
    RankedSales
WHERE 
    sales_rank <= 10
GROUP BY 
    ca_city
ORDER BY 
    total_revenue DESC;
