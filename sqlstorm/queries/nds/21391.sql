
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_paid) AS total_sales,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_quantity) DESC) AS sales_rank,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS revenue_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_month IS NOT NULL
        AND (c.c_birth_year BETWEEN 1960 AND 2000 OR c.c_birth_country IS NULL)
    GROUP BY 
        ws.ws_item_sk
),
sales_by_week AS (
    SELECT 
        dd.d_year,
        dd.d_week_seq,
        SUM(rs.total_quantity_sold) AS weekly_quantity,
        SUM(rs.total_sales) AS weekly_revenue
    FROM 
        date_dim dd
    JOIN 
        ranked_sales rs ON rs.total_quantity_sold IS NOT NULL
    GROUP BY 
        dd.d_year, dd.d_week_seq
),
high_revenue_weeks AS (
    SELECT 
        d_year,
        d_week_seq,
        weekly_quantity,
        weekly_revenue,
        ROW_NUMBER() OVER (ORDER BY weekly_revenue DESC) AS revenue_rank
    FROM 
        sales_by_week
    WHERE 
        weekly_revenue > 10000
),
store_info AS (
    SELECT 
        s.s_store_id,
        SUM(ss.ss_net_paid) AS store_sales
    FROM 
        store s 
    LEFT JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    WHERE 
        s.s_country = 'USA' OR s.s_state IS NULL
    GROUP BY 
        s.s_store_id
)
SELECT 
    hw.d_year,
    hw.d_week_seq,
    hw.weekly_quantity,
    hw.weekly_revenue,
    si.s_store_id,
    si.store_sales
FROM 
    high_revenue_weeks hw
LEFT JOIN 
    store_info si ON hw.weekly_revenue > si.store_sales * 1.5
WHERE 
    hw.revenue_rank <= 10
UNION ALL
SELECT 
    hh.d_year,
    hh.d_week_seq,
    hh.weekly_quantity,
    hh.weekly_revenue,
    NULL AS s_store_id,
    NULL AS store_sales
FROM 
    high_revenue_weeks hh
WHERE 
    hh.weekly_revenue IS NULL
ORDER BY 
    d_year, d_week_seq;
