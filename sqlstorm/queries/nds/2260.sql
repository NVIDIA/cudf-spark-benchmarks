
WITH SalesData AS (
    SELECT 
        s.s_store_sk,
        SUM(ss.ss_net_profit) AS total_store_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_sales_count,
        AVG(ss.ss_sales_price) AS avg_sales_price,
        SUM(ss.ss_ext_discount_amt) AS total_discount,
        DENSE_RANK() OVER (PARTITION BY s.s_state ORDER BY SUM(ss.ss_net_profit) DESC) AS rank_per_state
    FROM 
        store_sales ss
    JOIN 
        store s ON ss.ss_store_sk = s.s_store_sk
    WHERE 
        ss.ss_sold_date_sk BETWEEN 2451000 AND 2452000 
        AND ss.ss_net_paid > 0
    GROUP BY 
        s.s_store_sk, s.s_state
),
TopStores AS (
    SELECT 
        s.s_store_name,
        sd.total_store_profit,
        sd.total_sales_count,
        sd.avg_sales_price,
        sd.total_discount,
        sd.rank_per_state
    FROM 
        SalesData sd 
    JOIN 
        store s ON sd.s_store_sk = s.s_store_sk
    WHERE 
        sd.rank_per_state <= 5
)
SELECT 
    s.s_state,
    COALESCE(ts.s_store_name, 'N/A') AS store_name,
    COALESCE(ts.total_store_profit, 0) AS total_profit,
    COALESCE(ts.total_sales_count, 0) AS total_count,
    COALESCE(ts.avg_sales_price, 0) AS avg_price,
    COALESCE(ts.total_discount, 0) AS total_discount,
    NULLIF(SUM(ws.ws_quantity), 0) AS total_web_sales_quantity,
    100.0 * COALESCE(ts.total_store_profit, 0) / NULLIF(SUM(ws.ws_sales_price), 0) AS profit_percentage 
FROM 
    store s 
LEFT JOIN 
    TopStores ts ON s.s_store_name = ts.s_store_name
LEFT JOIN 
    web_sales ws ON ws.ws_ship_addr_sk = s.s_store_sk
GROUP BY 
    s.s_state, ts.s_store_name, ts.total_store_profit, ts.total_sales_count, ts.avg_sales_price, ts.total_discount
ORDER BY 
    s.s_state, total_profit DESC;
