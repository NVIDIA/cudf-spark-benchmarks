
WITH RankedSales AS (
    SELECT 
        ws.ws_web_site_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        DENSE_RANK() OVER (ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM 
        web_sales ws
    INNER JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2022
        AND dd.d_month_seq IN (1, 2)
    GROUP BY 
        ws.ws_web_site_sk
),
TopWebSites AS (
    SELECT 
        rw.ws_web_site_sk,
        rw.total_net_profit,
        w.w_warehouse_name,
        w.w_city
    FROM 
        RankedSales rw
    JOIN 
        warehouse w ON rw.ws_web_site_sk = w.w_warehouse_sk
    WHERE 
        rw.rank <= 5
)
SELECT 
    tws.ws_web_site_sk,
    tws.total_net_profit,
    tws.w_warehouse_name,
    tws.w_city,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    AVG(ws.ws_net_paid) AS avg_net_paid
FROM 
    TopWebSites tws
JOIN 
    web_sales ws ON tws.ws_web_site_sk = ws.ws_web_site_sk
GROUP BY 
    tws.ws_web_site_sk,
    tws.total_net_profit,
    tws.w_warehouse_name,
    tws.w_city
ORDER BY 
    tws.total_net_profit DESC;
