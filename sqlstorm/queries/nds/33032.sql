
WITH  sales_by_month AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        web_sales
    JOIN 
        date_dim d ON d.d_date_sk = ws_sold_date_sk
    GROUP BY 
        d.d_year, d.d_month_seq
    UNION ALL
    SELECT 
        d.d_year,
        d.d_month_seq,
        SUM(cs_ext_sales_price) AS total_sales
    FROM 
        catalog_sales
    JOIN 
        date_dim d ON d.d_date_sk = cs_sold_date_sk
    GROUP BY 
        d.d_year, d.d_month_seq
),
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        SUM(COALESCE(ws.ws_net_profit, 0) + COALESCE(cs.cs_net_profit, 0)) AS total_profit
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
),
price_analysis AS (
    SELECT 
        i.i_item_id,
        AVG(i.i_current_price) AS avg_price,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_order_count
    FROM 
        item i
    LEFT JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    LEFT JOIN 
        catalog_sales cs ON i.i_item_sk = cs.cs_item_sk
    GROUP BY 
        i.i_item_id
)
SELECT 
    s.d_year AS year,
    SUM(s.total_sales) AS total_sales,
    COUNT(DISTINCT cs.c_customer_sk) AS customer_count,
    AVG(pa.avg_price) AS avg_item_price
FROM 
    sales_by_month s
JOIN 
    customer_summary cs ON s.d_year = cs.c_customer_sk
LEFT JOIN 
    price_analysis pa ON pa.order_count > 0
WHERE 
    s.total_sales IS NOT NULL 
    AND cs.total_profit > (SELECT AVG(total_profit) FROM customer_summary)
GROUP BY 
    s.d_year
ORDER BY 
    s.d_year DESC;
