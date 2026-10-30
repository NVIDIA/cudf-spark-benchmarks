
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_net_paid) AS avg_payment,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        c.c_customer_id
), StoreSales AS (
    SELECT 
        s.s_store_id,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        AVG(ss.ss_net_paid) AS avg_payment,
        COUNT(DISTINCT ss.ss_ticket_number) AS transaction_count
    FROM 
        store s
    JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    JOIN 
        date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        s.s_store_id
), WebSales AS (
    SELECT 
        w.web_site_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(*) AS sale_count
    FROM 
        web_site w
    JOIN 
        web_sales ws ON w.web_site_sk = ws.ws_web_site_sk
    GROUP BY 
        w.web_site_id
)
SELECT 
    cs.c_customer_id,
    cs.total_sales AS customer_total_sales,
    cs.avg_payment AS customer_avg_payment,
    ss.s_store_id,
    ss.total_sales AS store_total_sales,
    ss.avg_payment AS store_avg_payment,
    ws.web_site_id,
    ws.total_sales AS web_total_sales,
    ws.sale_count AS web_sale_count
FROM 
    CustomerSales cs
JOIN 
    StoreSales ss ON cs.total_sales > 1000
JOIN 
    WebSales ws ON ws.total_sales > 5000
ORDER BY 
    cs.total_sales DESC, ss.total_sales DESC, ws.total_sales DESC;
