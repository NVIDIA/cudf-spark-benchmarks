WITH  MonthlySales AS (
    SELECT
        d.d_month_seq,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM
        date_dim d
    JOIN web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY
        d.d_month_seq
    
    UNION ALL

    SELECT
        d.d_month_seq,
        SUM(cs.cs_ext_sales_price) AS total_sales
    FROM
        date_dim d
    JOIN catalog_sales cs ON d.d_date_sk = cs.cs_sold_date_sk
    GROUP BY
        d.d_month_seq
),
SaleSummary AS (
    SELECT
        w.w_warehouse_id,
        SUM(ss.ss_sales_price) AS total_store_sales,
        AVG(ss.ss_net_profit) AS average_profit
    FROM
        store_sales ss
    JOIN warehouse w ON ss.ss_store_sk = w.w_warehouse_sk
    GROUP BY
        w.w_warehouse_id
),
TopSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS customer_sales,
        RANK() OVER (ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_id
)
SELECT 
    w.w_warehouse_id,
    ms.d_month_seq,
    ms.total_sales AS online_sales,
    ss.total_store_sales,
    ss.average_profit,
    ts.customer_sales,
    ts.sales_rank
FROM 
    MonthlySales ms
JOIN SaleSummary ss ON ms.d_month_seq IN (1, 2, 3) 
JOIN TopSales ts ON ts.customer_sales > 1000 
JOIN warehouse w ON w.w_warehouse_sk = ss.total_store_sales
WHERE 
    ss.total_store_sales IS NOT NULL
ORDER BY 
    w.w_warehouse_id, ms.d_month_seq;