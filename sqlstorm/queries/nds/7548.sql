
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        SUM(COALESCE(ss.ss_net_paid, 0) + COALESCE(cs.cs_net_paid, 0) + COALESCE(ws.ws_net_paid, 0)) AS total_sales
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
), SalesByDate AS (
    SELECT 
        dd.d_date, 
        SUM(cs.total_sales) AS daily_sales
    FROM 
        date_dim dd
    JOIN 
        CustomerSales cs ON dd.d_date_sk = cs.c_customer_sk
    GROUP BY 
        dd.d_date
), RankedSales AS (
    SELECT 
        s.d_date, 
        s.daily_sales, 
        RANK() OVER (ORDER BY s.daily_sales DESC) AS sales_rank
    FROM 
        SalesByDate s
)
SELECT 
    r.d_date, 
    r.daily_sales, 
    r.sales_rank
FROM 
    RankedSales r
WHERE 
    r.sales_rank <= 10
ORDER BY 
    r.sales_rank;
