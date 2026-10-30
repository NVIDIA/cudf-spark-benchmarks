WITH ranked_customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_customer_id, cd.cd_gender
), recent_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        COALESCE(SUM(CASE WHEN d.d_date >= cast('2002-10-01' as date) - INTERVAL '30 DAY' THEN ws.ws_ext_sales_price END), 0) AS recent_sales,
        COUNT(DISTINCT CASE WHEN d.d_date >= cast('2002-10-01' as date) - INTERVAL '30 DAY' THEN ws.ws_order_number END) AS recent_orders
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        c.c_customer_sk, c.c_customer_id, cd.cd_gender
)
SELECT 
    rcs.c_customer_id,
    rcs.total_sales,
    rcs.order_count,
    rcs.sales_rank,
    rs.recent_sales,
    rs.recent_orders,
    DENSE_RANK() OVER (ORDER BY rcs.total_sales DESC) AS overall_rank
FROM 
    ranked_customer_sales rcs
JOIN 
    recent_sales rs ON rcs.c_customer_sk = rs.c_customer_sk
WHERE 
    rcs.sales_rank <= 10
ORDER BY 
    rcs.total_sales DESC, rs.recent_sales DESC;