
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rank_profit,
        SUM(ws.ws_quantity) OVER (PARTITION BY ws.ws_item_sk) AS total_quantity,
        SUM(ws.ws_net_paid) OVER (PARTITION BY ws.ws_item_sk) AS total_net_paid
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 20230101 AND 20231231
),
MaxProfit AS (
    SELECT 
        r.ws_item_sk,
        r.ws_order_number,
        r.ws_net_profit
    FROM 
        RankedSales r
    WHERE 
        r.rank_profit = 1
),
StoreSalesAggregate AS (
    SELECT 
        ss.ss_item_sk,
        COUNT(ss.ss_ticket_number) AS total_sales,
        AVG(ss.ss_net_profit) AS avg_net_profit,
        SUM(ss.ss_ext_discount_amt) AS total_discount
    FROM 
        store_sales ss
    GROUP BY 
        ss.ss_item_sk
),
ItemDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        COALESCE(MAX(savg.total_sales), 0) AS max_store_sales,
        COALESCE(MAX(savg.avg_net_profit), 0) AS max_avg_profit,
        COALESCE(MAX(savg.total_discount), 0) AS total_discount
    FROM 
        item i
    LEFT JOIN 
        StoreSalesAggregate savg ON i.i_item_sk = savg.ss_item_sk
    GROUP BY 
        i.i_item_sk, i.i_item_desc
)
SELECT 
    id.i_item_sk,
    id.i_item_desc,
    mp.ws_net_profit AS max_online_profit,
    id.max_store_sales,
    id.max_avg_profit,
    CASE 
        WHEN id.max_store_sales > 0 THEN (mp.ws_net_profit / id.max_store_sales)
        ELSE NULL
    END AS online_to_store_ratio,
    id.total_discount,
    (SELECT COUNT(*) FROM customer c WHERE c.c_current_cdemo_sk IS NOT NULL) AS customer_count,
    (SELECT COUNT(DISTINCT cr.cr_order_number) 
     FROM catalog_returns cr 
     WHERE cr.cr_item_sk = mp.ws_item_sk 
     AND cr.cr_return_quantity > 0) AS total_catalog_returns
FROM 
    MaxProfit mp
JOIN 
    ItemDetails id ON mp.ws_item_sk = id.i_item_sk
WHERE 
    (id.total_discount IS NOT NULL OR id.total_discount IS NULL)
    AND (id.max_store_sales >= 5 OR mp.ws_net_profit > 100)
ORDER BY 
    COALESCE(mp.ws_net_profit, 0) DESC, 
    id.i_item_desc;
