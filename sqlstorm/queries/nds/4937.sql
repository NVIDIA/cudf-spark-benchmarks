
WITH monthly_sales AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year, d.d_month_seq
),
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, ca.ca_city, ca.ca_state, cd.cd_gender
),
top_customers AS (
    SELECT 
        c.c_customer_sk,
        cs.total_profit,
        RANK() OVER (ORDER BY cs.total_profit DESC) AS customer_rank
    FROM 
        customer_summary cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
)
SELECT 
    ts.c_customer_sk,
    ts.total_profit,
    ms.d_year,
    ms.d_month_seq,
    ms.total_sales,
    ms.order_count
FROM 
    top_customers ts
JOIN 
    monthly_sales ms ON ts.customer_rank <= 10
WHERE 
    ms.total_sales > (SELECT AVG(total_sales) FROM monthly_sales WHERE d_year = ms.d_year)
ORDER BY 
    ts.total_profit DESC, ms.total_sales DESC;
