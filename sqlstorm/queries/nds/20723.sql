
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk, 
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rn
    FROM 
        web_sales ws 
    WHERE 
        ws.ws_sold_date_sk BETWEEN 1 AND 100
),
TopWebSales AS (
    SELECT 
        r.ws_order_number,
        r.ws_item_sk,
        r.ws_net_profit
    FROM 
        RankedSales r
    WHERE 
        r.rn <= 3
),
StoreSalesWithPromotions AS (
    SELECT 
        ss.ss_ticket_number,
        ss.ss_item_sk,
        ss.ss_net_profit,
        COALESCE(p.p_discount_active, 'N') AS promo_active
    FROM 
        store_sales ss
    LEFT JOIN 
        promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE 
        ss.ss_sales_price > 20.00 AND 
        ss.ss_net_profit IS NOT NULL
),
WebReturns AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returns,
        SUM(wr.wr_return_amt) AS total_return_amount
    FROM 
        web_returns wr
    WHERE 
        wr.wr_reason_sk IS NOT NULL
    GROUP BY 
        wr.wr_item_sk
),
FinalReport AS (
    SELECT 
        tws.ws_order_number,
        tws.ws_item_sk,
        SUM(tws.ws_net_profit) AS total_web_profit,
        SUM(COALESCE(sr.total_returns, 0)) AS total_store_returns,
        AVG(ss.ss_net_profit) AS average_store_profit
    FROM 
        TopWebSales tws
    FULL OUTER JOIN 
        StoreSalesWithPromotions ss ON tws.ws_item_sk = ss.ss_item_sk
    LEFT JOIN 
        WebReturns sr ON tws.ws_item_sk = sr.wr_item_sk
    WHERE 
        tws.ws_net_profit IS NOT NULL OR ss.ss_net_profit IS NOT NULL
    GROUP BY 
        tws.ws_order_number, 
        tws.ws_item_sk
)
SELECT 
    fr.ws_order_number,
    fr.ws_item_sk,
    fr.total_web_profit,
    fr.total_store_returns,
    fr.average_store_profit
FROM 
    FinalReport fr
WHERE 
    (fr.total_web_profit > 1000 OR fr.average_store_profit < 100)
    AND fr.total_store_returns IS NOT NULL
ORDER BY 
    fr.total_web_profit DESC, fr.average_store_profit ASC
LIMIT 10;
