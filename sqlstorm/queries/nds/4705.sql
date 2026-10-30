
WITH RankedSales AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ws.ws_sold_date_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ci.c_customer_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        customer ci
    JOIN 
        web_sales ws ON ci.c_customer_sk = ws.ws_ship_customer_sk
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        ci.c_customer_sk, ci.c_first_name, ci.c_last_name, ws.ws_sold_date_sk
),
TopCustomers AS (
    SELECT 
        c1.c_customer_sk,
        c1.c_first_name,
        c1.c_last_name,
        c1.c_birth_year,
        cs.total_sales
    FROM 
        RankedSales cs
    JOIN 
        customer c1 ON cs.c_customer_sk = c1.c_customer_sk 
    WHERE 
        cs.sales_rank <= 10
),
SalesAnalysis AS (
    SELECT 
        tc.c_customer_sk,
        tc.c_first_name,
        tc.c_last_name,
        tc.c_birth_year,
        COALESCE(SUM(ss.ss_quantity), 0) AS store_sales_quantity,
        COALESCE(SUM(st.total_sales), 0) AS total_web_sales
    FROM 
        TopCustomers tc
    LEFT JOIN 
        store_sales ss ON tc.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        (SELECT 
            ws.ws_ship_customer_sk, 
            SUM(ws.ws_sales_price) AS total_sales
         FROM 
            web_sales ws 
         GROUP BY 
             ws.ws_ship_customer_sk) st ON st.ws_ship_customer_sk = tc.c_customer_sk
    GROUP BY 
        tc.c_customer_sk, tc.c_first_name, tc.c_last_name, tc.c_birth_year
)
SELECT 
    sa.c_customer_sk,
    sa.c_first_name,
    sa.c_last_name,
    sa.c_birth_year,
    sa.store_sales_quantity,
    sa.total_web_sales,
    (sa.store_sales_quantity / NULLIF(sa.total_web_sales, 0)) AS ratio_sales
FROM 
    SalesAnalysis sa
WHERE 
    sa.total_web_sales > 0
ORDER BY 
    ratio_sales DESC
LIMIT 50;
