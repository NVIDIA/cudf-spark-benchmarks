
WITH  sales_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_profit,
        CASE 
            WHEN COALESCE(SUM(ws.ws_net_profit), 0) > 500 THEN 'High'
            WHEN COALESCE(SUM(ws.ws_net_profit), 0) BETWEEN 200 AND 500 THEN 'Medium'
            ELSE 'Low'
        END AS profit_category
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
monthly_sales AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        SUM(ws.ws_sales_price) AS monthly_sales_total,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        d.d_year, d.d_month_seq
)
SELECT 
    sh.c_customer_sk,
    sh.c_first_name,
    sh.c_last_name,
    sh.cd_gender,
    sh.cd_marital_status,
    sh.total_profit,
    sh.profit_category,
    ms.d_year,
    ms.d_month_seq,
    ms.monthly_sales_total,
    ms.total_orders
FROM 
    sales_hierarchy sh
FULL OUTER JOIN 
    monthly_sales ms ON sh.total_profit > 0 OR ms.monthly_sales_total IS NOT NULL
WHERE 
    (sh.cd_gender = 'F' OR sh.cd_marital_status = 'M') 
    AND ms.monthly_sales_total IS NOT NULL
ORDER BY 
    ms.d_year DESC, 
    ms.d_month_seq DESC;
