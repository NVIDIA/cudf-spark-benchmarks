
WITH  sales_cte AS (
    SELECT 
        ws_order_number,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_item_sk) AS item_count,
        DENSE_RANK() OVER (ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_order_number
), 
customer_info AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_credit_rating
),
store_info AS (
    SELECT
        s.s_store_id,
        s.s_city,
        SUM(ss.ss_ext_sales_price) AS total_store_sales
    FROM 
        store s 
    JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY 
        s.s_store_id, 
        s.s_city
),
recent_trends AS (
    SELECT 
        d.d_year,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        date_dim d 
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    WHERE 
        d.d_year >= 1999
    GROUP BY 
        d.d_year
)
SELECT 
    cs.c_customer_id,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.cd_credit_rating,
    cs.total_sales,
    cs.order_count,
    ss.total_store_sales,
    rt.total_orders,
    rt.total_profit,
    CASE 
        WHEN cs.total_sales IS NULL THEN 'No Sales'
        WHEN cs.order_count IS NULL THEN 'No Orders'
        ELSE 'Active Customer'
    END AS customer_status
FROM 
    customer_info cs
LEFT JOIN 
    store_info ss ON ss.s_store_id = (
        SELECT 
            s.s_store_id 
        FROM 
            store s 
        ORDER BY 
            s.s_number_employees DESC 
        LIMIT 1
    )
LEFT JOIN 
    recent_trends rt ON rt.d_year = EXTRACT(YEAR FROM DATE '2002-10-01')
WHERE 
    cs.order_count >= (SELECT AVG(order_count) FROM customer_info)
AND 
    (cs.total_sales IS NOT NULL
OR 
    cs.cd_gender IS NULL
OR 
    cs.cd_marital_status IS NULL)
ORDER BY 
    cs.total_sales DESC, 
    cs.order_count DESC;
