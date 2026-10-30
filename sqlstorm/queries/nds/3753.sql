
WITH RankedSales AS (
    SELECT 
        ws_item_sk, 
        ws_order_number, 
        ws_sales_price, 
        ws_net_profit,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS profit_rank
    FROM 
        web_sales
    WHERE 
        ws_sales_price > 0
),
ReturnsSummary AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returns,
        SUM(wr_return_amt) AS total_return_amt
    FROM 
        web_returns
    GROUP BY 
        wr_item_sk
),
PromotionalSales AS (
    SELECT 
        cs_item_sk,
        SUM(cs_net_profit) AS promo_net_profit
    FROM 
        catalog_sales
    INNER JOIN 
        promotion ON cs_promo_sk = p_promo_sk
    WHERE 
        p_discount_active = 'Y'
    GROUP BY 
        cs_item_sk
)
SELECT 
    i.i_item_id,
    COALESCE(RS.ws_sales_price, 0) AS last_known_price,
    COALESCE(SUM(RS.ws_net_profit), 0) AS total_web_net_profit,
    COALESCE(RT.total_returns, 0) AS total_web_returns,
    COALESCE(PS.promo_net_profit, 0) AS total_promo_net_profit
FROM 
    item i
LEFT JOIN 
    RankedSales RS ON i.i_item_sk = RS.ws_item_sk AND RS.profit_rank = 1
LEFT JOIN 
    ReturnsSummary RT ON i.i_item_sk = RT.wr_item_sk
LEFT JOIN 
    PromotionalSales PS ON i.i_item_sk = PS.cs_item_sk
GROUP BY 
    i.i_item_id, RS.ws_sales_price, RT.total_returns, PS.promo_net_profit
HAVING 
    (COALESCE(SUM(RS.ws_net_profit), 0) > 1000 OR COALESCE(PS.promo_net_profit, 0) > 500)
    AND COALESCE(RT.total_returns, 0) < 50
ORDER BY 
    total_web_net_profit DESC, total_web_returns ASC;
