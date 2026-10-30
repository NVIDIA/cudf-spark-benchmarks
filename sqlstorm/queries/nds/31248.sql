
WITH  SalesCTE AS (
    SELECT ws_item_sk,
           SUM(ws_quantity) AS total_sold,
           SUM(ws_net_profit) AS total_profit,
           ROW_NUMBER() OVER (ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM web_sales
    GROUP BY ws_item_sk
),
PromotionDetails AS (
    SELECT p_promo_sk,
           p_promo_name,
           SUM(COALESCE(ws_ext_discount_amt, 0)) AS total_discount,
           SUM(ws_net_paid_inc_tax) AS total_sales
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    GROUP BY p.p_promo_sk, p.p_promo_name
),
HighProfitItems AS (
    SELECT s.ws_item_sk,
           s.total_sold,
           s.total_profit,
           COALESCE(pd.total_discount, 0) AS total_discount,
           CASE WHEN pd.total_discount > 0 THEN (s.total_profit / pd.total_discount) ELSE NULL END AS profit_to_discount_ratio
    FROM SalesCTE s
    LEFT JOIN PromotionDetails pd ON s.ws_item_sk = pd.p_promo_sk
    WHERE s.rank <= 10
)
SELECT hi.ws_item_sk,
       hi.total_sold,
       hi.total_profit,
       hi.total_discount,
       hi.profit_to_discount_ratio,
       (SELECT COUNT(*) FROM store_returns sr WHERE sr.sr_item_sk = hi.ws_item_sk) AS total_returns,
       (CASE WHEN hi.total_profit IS NOT NULL THEN hi.total_profit ELSE 0 END) - 
       (SELECT COALESCE(SUM(sr_return_amt), 0) FROM store_returns sr WHERE sr.sr_item_sk = hi.ws_item_sk) AS net_profit_after_returns
FROM HighProfitItems hi
ORDER BY hi.total_profit DESC
LIMIT 50;
