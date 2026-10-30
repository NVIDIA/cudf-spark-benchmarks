
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price) AS total_spent,
        DENSE_RANK() OVER (ORDER BY SUM(ws.ws_sales_price) DESC) AS spend_rank
    FROM 
        customer c
        JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
),
HighSpenders AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.cd_gender,
        cs.total_orders,
        cs.total_spent,
        cs.spend_rank
    FROM 
        CustomerStats cs
    WHERE 
        cs.spend_rank <= 10
),
StoreInfo AS (
    SELECT 
        s.s_store_sk,
        s.s_store_name,
        SUM(ss.ss_net_paid) AS total_sales,
        COUNT(ss.ss_ticket_number) AS transaction_count
    FROM 
        store s
        LEFT JOIN store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY 
        s.s_store_sk, s.s_store_name
)
SELECT 
    hs.c_first_name,
    hs.c_last_name,
    hs.cd_gender,
    si.s_store_name,
    si.total_sales,
    si.transaction_count,
    COALESCE(si.total_sales, 0) AS sales_with_fallback,
    CASE 
        WHEN si.total_sales IS NULL THEN 'No Sales'
        ELSE 'Has Sales'
    END AS sales_status
FROM 
    HighSpenders hs
    FULL OUTER JOIN StoreInfo si ON si.total_sales > 10000
ORDER BY 
    hs.total_spent DESC;
