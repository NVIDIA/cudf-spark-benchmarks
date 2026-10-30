
WITH  customer_revenue AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_paid_inc_tax) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS rank_revenue
    FROM 
        customer c 
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year IS NOT NULL AND c.c_preferred_cust_flag = 'Y'
    GROUP BY 
        c.c_customer_sk
    HAVING 
        SUM(ws.ws_net_paid_inc_tax) > (SELECT AVG(total_revenue) FROM (SELECT 
                                                                SUM(ws_net_paid_inc_tax) AS total_revenue 
                                                            FROM 
                                                                web_sales 
                                                            GROUP BY 
                                                                ws_bill_customer_sk) AS avg_rev)
),
customer_with_address AS (
    SELECT 
        cr.c_customer_sk,
        ca.ca_city,
        ca.ca_state,
        cr.total_revenue
    FROM 
        customer_revenue cr 
    LEFT JOIN 
        customer_address ca ON cr.c_customer_sk = ca.ca_address_sk
),
ranked_customers AS (
    SELECT 
        cwa.*,
        DENSE_RANK() OVER (ORDER BY cwa.total_revenue DESC) AS revenue_rank
    FROM 
        customer_with_address cwa
)
SELECT 
    r.*,
    COALESCE(r.ca_city, 'Unknown City') AS final_city,
    COALESCE(r.ca_state, 'Unknown State') AS final_state,
    CASE 
        WHEN r.revenue_rank <= 10 THEN 'Top Customer'
        WHEN r.revenue_rank <= 50 THEN 'Moderate Customer'
        ELSE 'New Customer'
    END AS customer_category
FROM 
    ranked_customers r
WHERE 
    r.total_revenue IS NOT NULL 
    AND r.revenue_rank <= 100
ORDER BY 
    r.total_revenue DESC
LIMIT 20;
