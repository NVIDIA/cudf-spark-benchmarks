
WITH Revenue AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid_inc_tax) AS total_revenue,
        DENSE_RANK() OVER (PARTITION BY c.c_current_addr_sk ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS revenue_rank,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Male'
            WHEN cd.cd_gender = 'F' THEN 'Female'
            ELSE 'Other'
        END AS gender_category
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d.d_date_sk) 
                                    FROM date_dim d 
                                    WHERE d.d_year = 2023) AND 
                                   (SELECT MAX(d.d_date_sk) 
                                    FROM date_dim d 
                                    WHERE d.d_year = 2023)
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, c.c_current_addr_sk
),
TopRevenueByAddress AS (
    SELECT
        r.c_customer_sk,
        r.c_first_name,
        r.c_last_name,
        r.total_revenue,
        r.revenue_rank,
        r.gender_category,
        ca.ca_city,
        ca.ca_state,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_address_sk ORDER BY r.total_revenue DESC) AS city_rank
    FROM 
        Revenue r
    JOIN 
        customer_address ca ON r.c_customer_sk = ca.ca_address_sk
    WHERE 
        r.revenue_rank <= 5
)
SELECT 
    tr.c_first_name,
    tr.c_last_name,
    tr.total_revenue,
    tr.ca_city,
    tr.ca_state,
    COALESCE(tr.city_rank, 0) AS city_rank
FROM 
    TopRevenueByAddress tr
WHERE 
    tr.total_revenue IS NOT NULL
ORDER BY 
    tr.total_revenue DESC
LIMIT 10;
