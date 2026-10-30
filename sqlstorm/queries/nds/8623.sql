
WITH Customer_Sales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c 
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
Store_Sales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_store_orders
    FROM 
        customer c 
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk
),
Combined_Sales AS (
    SELECT 
        cs.c_customer_sk,
        COALESCE(cs.total_web_sales, 0) AS total_web_sales,
        COALESCE(ss.total_store_sales, 0) AS total_store_sales,
        (COALESCE(cs.total_web_sales, 0) + COALESCE(ss.total_store_sales, 0)) AS total_sales,
        (COALESCE(cs.total_orders, 0) + COALESCE(ss.total_store_orders, 0)) AS total_orders
    FROM 
        Customer_Sales cs
    FULL OUTER JOIN 
        Store_Sales ss ON cs.c_customer_sk = ss.c_customer_sk
),
Customer_Demo AS (
    SELECT 
        cd.cd_demo_sk,
        COUNT(DISTINCT cs.c_customer_sk) AS num_customers,
        AVG(cs.total_sales) AS avg_sales,
        AVG(cs.total_orders) AS avg_orders
    FROM 
        Combined_Sales cs
    LEFT JOIN 
        customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_demo_sk
)
SELECT 
    cd.cd_demo_sk,
    cd.num_customers,
    cd.avg_sales,
    cd.avg_orders,
    d.d_year AS sales_year,
    d.d_month_seq AS sales_month
FROM 
    Customer_Demo cd
JOIN 
    date_dim d ON d.d_date_sk = (
        SELECT MAX(ws.ws_sold_date_sk) 
        FROM web_sales ws 
        WHERE ws.ws_bill_customer_sk IN (
            SELECT c.c_customer_sk 
            FROM customer c 
            JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        )
    )
ORDER BY 
    d.d_year, d.d_month_seq;
