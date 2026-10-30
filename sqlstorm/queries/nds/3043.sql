
WITH sales_summary AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid_inc_ship_tax) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_quantity) AS total_items,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ws.ws_net_paid_inc_ship_tax) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL
    GROUP BY 
        c.c_customer_id
), 
preferred_customers AS (
    SELECT 
        c.c_customer_id,
        d.d_year,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_net_paid_inc_tax) AS total_spending
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        c.c_preferred_cust_flag = 'Y' 
        AND d.d_year IN (2023, 2022)
    GROUP BY 
        c.c_customer_id, d.d_year, cd.cd_gender, cd.cd_marital_status
), 
ranked_customers AS (
    SELECT 
        pc.c_customer_id,
        pc.d_year,
        ROW_NUMBER() OVER (PARTITION BY pc.d_year ORDER BY pc.total_spending DESC) AS spending_rank
    FROM 
        preferred_customers pc
)
SELECT 
    r.c_customer_id,
    r.d_year,
    r.spending_rank,
    ss.total_sales,
    ss.total_orders,
    ss.total_items
FROM 
    ranked_customers r
LEFT JOIN 
    sales_summary ss ON r.c_customer_id = ss.c_customer_id
WHERE 
    r.spending_rank <= 10
ORDER BY 
    r.d_year, r.spending_rank;
