WITH  revenue_growth AS (
    SELECT 
        d.d_year, 
        SUM(ws.ws_net_paid) AS total_revenue
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        d.d_year
    UNION ALL
    SELECT 
        d.d_year, 
        SUM(cs.cs_net_paid) AS total_revenue
    FROM 
        date_dim d
    JOIN 
        catalog_sales cs ON d.d_date_sk = cs.cs_sold_date_sk
    GROUP BY 
        d.d_year
),
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
),
address_summary AS (
    SELECT 
        ca.ca_state,
        COUNT(DISTINCT c.c_customer_id) AS customer_count,
        AVG(cd.cd_dep_count) AS average_dependencies
    FROM 
        customer_address ca
    JOIN 
        customer c ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        ca.ca_state
),
final_summary AS (
    SELECT 
        a.ca_state,
        a.customer_count,
        a.average_dependencies,
        GREATEST(COALESCE(c.total_spent, 0), COALESCE(g.total_revenue, 0)) AS max_value
    FROM 
        address_summary a
    LEFT JOIN 
        customer_summary c ON a.customer_count > 100
    LEFT JOIN 
        (SELECT 
             d_year, 
             SUM(total_revenue) AS total_revenue 
         FROM 
             revenue_growth 
         GROUP BY 
             d_year) g ON g.d_year = EXTRACT(YEAR FROM cast('2002-10-01' as date))
)
SELECT 
    fs.ca_state,
    fs.customer_count,
    fs.average_dependencies,
    fs.max_value,
    CASE 
        WHEN fs.max_value IS NULL THEN 'No Activity'
        WHEN fs.max_value = 0 THEN 'Inactive'
        ELSE 'Active'
    END AS activity_status
FROM 
    final_summary fs
ORDER BY 
    fs.customer_count DESC;