
WITH  customer_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY c.c_customer_sk) AS row_num
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate IS NOT NULL
),
date_analysis AS (
    SELECT 
        d.d_date,
        EXTRACT(YEAR FROM d.d_date) AS year,
        EXTRACT(MONTH FROM d.d_date) AS month,
        COUNT(ws.ws_order_number) AS total_sales
    FROM 
        date_dim d
    LEFT JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    WHERE 
        d.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
    GROUP BY 
        d.d_date, year, month
),
join_analysis AS (
    SELECT 
        ca.ca_city,
        SUM(ws.ws_net_paid) AS total_net_paid,
        COALESCE(NULLIF(SUM(ws.ws_ext_discount_amt), 0), 1) AS avg_discount
    FROM 
        customer_address ca
    INNER JOIN 
        web_sales ws ON ca.ca_address_sk = ws.ws_bill_addr_sk
    GROUP BY 
        ca.ca_city
),
sales_summary AS (
    SELECT 
        ch.c_customer_id,
        ch.cd_gender,
        da.year,
        da.month,
        SUM(ch.cd_purchase_estimate) AS total_estimate,
        COUNT(*) AS sales_count
    FROM 
        customer_hierarchy ch
    JOIN 
        date_analysis da ON da.year = 2022
    GROUP BY 
        ch.c_customer_id, ch.cd_gender, da.year, da.month
)
SELECT 
    sa.c_customer_id,
    sa.cd_gender,
    sa.year,
    sa.month,
    sa.total_estimate,
    j.ca_city,
    j.total_net_paid,
    CASE 
        WHEN j.avg_discount < 0 THEN 'Negative Discount'
        ELSE 'Normal'
    END AS discount_status
FROM 
    sales_summary sa
JOIN 
    join_analysis j ON sa.c_customer_id = j.ca_city
WHERE 
    sa.total_estimate > 1000
ORDER BY 
    sa.year, sa.month, j.total_net_paid DESC
LIMIT 100;
