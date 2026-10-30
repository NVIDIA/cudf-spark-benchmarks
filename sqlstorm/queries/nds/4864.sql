WITH ranked_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ws.ws_net_paid) DESC) AS rn,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        DATE_TRUNC('month', d.d_date) AS sales_month
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2001
        AND d.d_dow NOT IN (6, 7) 
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating, d.d_date
),
monthly_avg_sales AS (
    SELECT 
        sales_month,
        AVG(total_sales) AS avg_sales
    FROM 
        ranked_sales
    WHERE 
        rn = 1 
    GROUP BY 
        sales_month
),
gender_sales_comparison AS (
    SELECT 
        r.cd_gender,
        COUNT(r.c_customer_id) AS num_customers,
        SUM(r.total_sales) AS total_sales,
        m.avg_sales
    FROM 
        ranked_sales r
    JOIN 
        monthly_avg_sales m ON r.sales_month = m.sales_month
    GROUP BY 
        r.cd_gender, m.avg_sales
),
exceeds_avg AS (
    SELECT 
        g.cd_gender,
        g.total_sales,
        g.avg_sales,
        CASE 
            WHEN g.total_sales > g.avg_sales THEN 'Above Average'
            WHEN g.total_sales < g.avg_sales THEN 'Below Average'
            ELSE 'Average'
        END AS performance
    FROM 
        gender_sales_comparison g
)
SELECT 
    e.cd_gender,
    COUNT(e.total_sales) AS count_performance,
    SUM(CASE WHEN e.performance = 'Above Average' THEN 1 ELSE 0 END) AS above_average_count,
    SUM(CASE WHEN e.performance = 'Below Average' THEN 1 ELSE 0 END) AS below_average_count
FROM 
    exceeds_avg e
GROUP BY 
    e.cd_gender
ORDER BY 
    count_performance DESC;