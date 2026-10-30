WITH  sales_data AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        SUM(ws_quantity) AS total_sold,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
monthly_sales AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        SUM(s.total_sold) AS monthly_sales,
        COUNT(DISTINCT s.ws_item_sk) AS unique_items_sold
    FROM 
        date_dim d
    JOIN 
        sales_data s ON d.d_date_sk = s.ws_sold_date_sk
    WHERE 
        s.rn = 1 
    GROUP BY 
        d.d_year, d.d_month_seq
),
high_performance_customers AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws_ext_sales_price) AS total_spent
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d.d_date_sk FROM date_dim d 
                                WHERE d.d_year = 2001 AND d.d_month_seq <= 6)
    GROUP BY 
        c.c_customer_sk
    HAVING 
        SUM(ws.ws_net_profit) > 1000 
),
sales_performance AS (
    SELECT 
        mh.d_year,
        mh.d_month_seq,
        COALESCE(mh.monthly_sales, 0) AS total_monthly_sales,
        COALESCE(hp.total_spent, 0) AS high_performers_spent
    FROM 
        monthly_sales mh
    FULL OUTER JOIN 
        high_performance_customers hp ON mh.d_year = 2001
    ORDER BY 
        mh.d_year, mh.d_month_seq
)
SELECT 
    sp.d_year, 
    sp.d_month_seq,
    sp.total_monthly_sales,
    sp.high_performers_spent,
    CASE 
        WHEN sp.high_performers_spent > 0 THEN (sp.total_monthly_sales / NULLIF(sp.high_performers_spent, 0))
        ELSE NULL 
    END AS sales_to_high_performer_ratio
FROM 
    sales_performance sp
WHERE 
    sp.d_year = 2001
ORDER BY 
    sp.d_month_seq;