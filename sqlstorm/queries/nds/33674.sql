
WITH  sales_summary AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid_inc_tax) AS total_sales
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
    UNION ALL
    SELECT 
        ss_sold_date_sk,
        ss_item_sk,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_net_paid_inc_tax) AS total_sales
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ss_sold_date_sk, ss_item_sk
),
ranked_sales AS (
    SELECT 
        ss.ws_item_sk,
        ss.total_quantity,
        ss.total_sales,
        RANK() OVER (PARTITION BY ss.ws_item_sk ORDER BY ss.total_sales DESC) AS sales_rank
    FROM 
        sales_summary ss
),
customer_agg AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
top_customers AS (
    SELECT 
        ca.c_customer_sk,
        ca.c_first_name,
        ca.c_last_name,
        ca.order_count,
        ca.total_spent,
        RANK() OVER (ORDER BY ca.total_spent DESC) AS customer_rank
    FROM 
        customer_agg ca
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.order_count,
    tc.total_spent,
    rs.total_quantity,
    rs.total_sales,
    rs.sales_rank
FROM 
    top_customers tc
JOIN 
    ranked_sales rs ON tc.c_customer_sk = rs.ws_item_sk
WHERE 
    tc.customer_rank <= 10 
    AND (rs.total_quantity IS NOT NULL OR rs.total_sales IS NOT NULL)
ORDER BY 
    tc.total_spent DESC, rs.total_sales DESC;
