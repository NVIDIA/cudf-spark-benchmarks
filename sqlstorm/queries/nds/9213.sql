WITH RankedSales AS (
    SELECT 
        s.s_store_sk,
        COUNT(DISTINCT ss_ticket_number) AS total_sales,
        SUM(ss_net_paid) AS total_revenue,
        RANK() OVER (PARTITION BY s.s_store_sk ORDER BY SUM(ss_net_paid) DESC) AS revenue_rank
    FROM 
        store s
    JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    WHERE 
        ss.ss_sold_date_sk BETWEEN 2452064 AND 2452570  
    GROUP BY 
        s.s_store_sk
),
TopStores AS (
    SELECT 
        r.s_store_sk,
        r.total_sales,
        r.total_revenue
    FROM 
        RankedSales r
    WHERE 
        r.revenue_rank <= 10
)
SELECT 
    s.s_store_name,
    ts.total_sales,
    ts.total_revenue,
    c.cc_name AS call_center_name,
    COUNT(DISTINCT ws.ws_order_number) AS total_web_sales
FROM 
    TopStores ts
JOIN 
    store s ON ts.s_store_sk = s.s_store_sk
LEFT JOIN 
    call_center c ON s.s_market_id = c.cc_mkt_id
LEFT JOIN 
    web_sales ws ON s.s_store_sk = ws.ws_ship_customer_sk
GROUP BY 
    s.s_store_name, ts.total_sales, ts.total_revenue, c.cc_name
ORDER BY 
    ts.total_revenue DESC;