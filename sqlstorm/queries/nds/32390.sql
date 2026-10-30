
WITH  sales_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_profit
    FROM 
        customer AS c 
    LEFT JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_email_address

    UNION ALL

    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        COALESCE(SUM(cs.cs_net_profit), 0) AS total_profit
    FROM 
        customer AS c 
    LEFT JOIN 
        catalog_sales AS cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_email_address
),
ranked_sales AS (
    SELECT 
        sh.c_customer_sk,
        sh.c_first_name,
        sh.c_last_name,
        sh.c_email_address,
        RANK() OVER (ORDER BY sh.total_profit DESC) AS profit_rank
    FROM 
        sales_hierarchy AS sh
),
filtered_sales AS (
    SELECT 
        rs.c_customer_sk,
        rs.c_first_name,
        rs.c_last_name,
        rs.c_email_address,
        rs.profit_rank
    FROM 
        ranked_sales AS rs
    WHERE 
        rs.profit_rank <= 10
)
SELECT 
    f.c_customer_sk,
    f.c_first_name,
    f.c_last_name,
    f.c_email_address,
    COALESCE(SUM(ws.ws_net_profit), 0) AS total_web_sales,
    COALESCE(SUM(cs.cs_net_profit), 0) AS total_catalog_sales
FROM 
    filtered_sales AS f
LEFT JOIN 
    web_sales AS ws ON f.c_customer_sk = ws.ws_ship_customer_sk
LEFT JOIN 
    catalog_sales AS cs ON f.c_customer_sk = cs.cs_ship_customer_sk
GROUP BY 
    f.c_customer_sk, f.c_first_name, f.c_last_name, f.c_email_address
ORDER BY 
    f.c_customer_sk;
