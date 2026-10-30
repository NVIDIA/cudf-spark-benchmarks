
WITH WebSalesSummary AS (
    SELECT 
        w.ws_order_number,
        w.ws_item_sk,
        SUM(w.ws_quantity) AS total_quantity,
        SUM(w.ws_net_profit) AS total_net_profit,
        d.d_year,
        d.d_month_seq,
        d.d_week_seq
    FROM 
        web_sales w
    JOIN 
        date_dim d ON w.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        w.ws_order_number, w.ws_item_sk, d.d_year, d.d_month_seq, d.d_week_seq
),
StoreSalesSummary AS (
    SELECT 
        s.ss_ticket_number,
        s.ss_item_sk,
        SUM(s.ss_quantity) AS total_quantity,
        SUM(s.ss_net_profit) AS total_net_profit,
        d.d_year,
        d.d_month_seq,
        d.d_week_seq
    FROM 
        store_sales s
    JOIN 
        date_dim d ON s.ss_sold_date_sk = d.d_date_sk
    GROUP BY 
        s.ss_ticket_number, s.ss_item_sk, d.d_year, d.d_month_seq, d.d_week_seq
),
TotalSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.total_quantity AS web_quantity,
        ws.total_net_profit AS web_net_profit,
        ss.total_quantity AS store_quantity,
        ss.total_net_profit AS store_net_profit,
        ws.d_year,
        ws.d_month_seq,
        ws.d_week_seq
    FROM 
        WebSalesSummary ws
    FULL OUTER JOIN 
        StoreSalesSummary ss ON ws.ws_item_sk = ss.ss_item_sk AND ws.ws_order_number = ss.ss_ticket_number
)
SELECT 
    t.ws_item_sk,
    COALESCE(web_quantity, 0) AS web_quantity,
    COALESCE(store_quantity, 0) AS store_quantity,
    COALESCE(web_net_profit, 0) AS web_net_profit,
    COALESCE(store_net_profit, 0) AS store_net_profit,
    t.d_year,
    t.d_month_seq,
    t.d_week_seq
FROM 
    TotalSales t
WHERE 
    t.d_year = 2023 AND t.d_month_seq IN (1, 2, 3) 
ORDER BY 
    t.ws_item_sk, t.d_year, t.d_month_seq, t.d_week_seq;
