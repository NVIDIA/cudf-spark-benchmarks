
WITH sales_summary AS (
    SELECT 
        c.c_customer_id,
        SUM(ss.ss_net_profit) AS total_sales_profit,
        COUNT(ss.ss_ticket_number) AS total_transactions,
        AVG(ss.ss_sales_price) AS avg_sales_price,
        AVG(ss.ss_net_paid_inc_tax) AS avg_net_paid
    FROM 
        customer AS c
    JOIN 
        store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim AS d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE 
        cd.cd_gender = 'F' 
        AND d.d_year = 2000 
        AND d.d_moy BETWEEN 1 AND 3 
    GROUP BY 
        c.c_customer_id
),
top_sales AS (
    SELECT 
        c_customer_id AS customer_id,
        total_sales_profit,
        total_transactions,
        avg_sales_price,
        avg_net_paid
    FROM 
        sales_summary
    ORDER BY 
        total_sales_profit DESC
    LIMIT 10
)
SELECT 
    ts.customer_id,
    ts.total_sales_profit,
    ts.total_transactions,
    ts.avg_sales_price,
    ts.avg_net_paid,
    ca.ca_city,
    ca.ca_state
FROM 
    top_sales AS ts
JOIN 
    customer AS c ON ts.customer_id = c.c_customer_id
JOIN 
    customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
ORDER BY 
    ts.total_sales_profit DESC;
