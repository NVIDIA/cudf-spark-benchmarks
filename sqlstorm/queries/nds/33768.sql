
WITH  sales_data AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_sales,
        SUM(ws_ext_sales_price) AS total_revenue
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
    UNION ALL
    SELECT 
        cs_sold_date_sk,
        cs_item_sk,
        SUM(cs_quantity) AS total_sales,
        SUM(cs_ext_sales_price) AS total_revenue
    FROM 
        catalog_sales
    GROUP BY 
        cs_sold_date_sk, cs_item_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ss_ext_sales_price) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_sales s ON c.c_customer_sk = s.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
ranked_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.cd_gender,
        c.cd_marital_status,
        c.total_spent,
        RANK() OVER (ORDER BY c.total_spent DESC) AS spending_rank
    FROM 
        customer_info c
),
daily_sales AS (
    SELECT 
        d.d_date,
        SUM(sd.total_sales) AS total_sales,
        SUM(sd.total_revenue) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY d.d_date ORDER BY SUM(sd.total_revenue) DESC) AS daily_rank
    FROM 
        sales_data sd
    JOIN 
        date_dim d ON d.d_date_sk = sd.ws_sold_date_sk
    GROUP BY 
        d.d_date
)
SELECT 
    r.c_first_name,
    r.c_last_name,
    r.cd_gender,
    r.cd_marital_status,
    r.total_spent,
    ds.total_sales,
    ds.total_revenue,
    CASE 
        WHEN ds.total_revenue IS NULL THEN 'No Sales'
        ELSE 'Sales Recorded'
    END AS sales_status
FROM 
    ranked_customers r
LEFT JOIN 
    daily_sales ds ON r.total_spent = ds.total_revenue
WHERE 
    r.spending_rank <= 100
ORDER BY 
    r.total_spent DESC;
