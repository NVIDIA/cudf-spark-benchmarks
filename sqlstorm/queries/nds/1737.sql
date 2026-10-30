
WITH customer_stats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
top_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.order_count,
        cs.total_net_profit,
        RANK() OVER (ORDER BY cs.total_net_profit DESC) AS customer_rank
    FROM 
        customer_stats cs
    WHERE 
        cs.total_net_profit > 1000
),
yearly_sales AS (
    SELECT 
        d.d_year,
        SUM(ws.ws_net_paid) AS total_sales
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        d.d_year
),
sales_growth AS (
    SELECT 
        y1.d_year AS current_year,
        y1.total_sales AS current_year_sales,
        y2.total_sales AS previous_year_sales,
        CASE 
            WHEN y2.total_sales IS NULL THEN NULL 
            ELSE (y1.total_sales - y2.total_sales) / y2.total_sales * 100 
        END AS growth_percentage
    FROM 
        yearly_sales y1
    LEFT JOIN 
        yearly_sales y2 ON y1.d_year = y2.d_year + 1
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.order_count,
    tc.total_net_profit,
    sg.current_year,
    sg.current_year_sales,
    sg.previous_year_sales,
    sg.growth_percentage
FROM 
    top_customers tc
JOIN 
    sales_growth sg ON sg.growth_percentage IS NOT NULL
WHERE 
    tc.customer_rank <= 10
ORDER BY 
    tc.total_net_profit DESC, sg.growth_percentage DESC;

