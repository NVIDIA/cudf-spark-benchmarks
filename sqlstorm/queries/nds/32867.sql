WITH  SalesCTE AS (
    SELECT ss_item_sk, 
           SUM(ss_net_profit) AS total_net_profit,
           COUNT(DISTINCT ss_ticket_number) AS total_sales,
           ROW_NUMBER() OVER (PARTITION BY ss_item_sk ORDER BY SUM(ss_net_profit) DESC) AS rank
    FROM store_sales 
    GROUP BY ss_item_sk
), 
ItemDetails AS (
    SELECT i.i_item_sk, 
           i.i_item_desc, 
           COALESCE(s.total_net_profit, 0) AS total_net_profit,
           COALESCE(s.total_sales, 0) AS total_sales
    FROM item i
    LEFT JOIN SalesCTE s ON i.i_item_sk = s.ss_item_sk
), 
HighProfitItems AS (
    SELECT id.i_item_sk, 
           id.i_item_desc, 
           id.total_net_profit, 
           id.total_sales,
           ROW_NUMBER() OVER (ORDER BY id.total_net_profit DESC) AS profit_rank
    FROM ItemDetails id
    WHERE id.total_net_profit > (
        SELECT AVG(total_net_profit)
        FROM ItemDetails
        WHERE total_net_profit IS NOT NULL
    )
)
SELECT hp.i_item_sk, 
       hp.i_item_desc, 
       hp.total_net_profit, 
       hp.total_sales, 
       (SELECT COUNT(*) FROM web_sales ws WHERE ws.ws_sold_date_sk = DATE_PART('year', cast('2002-10-01' as date))) AS total_web_sales_this_year
FROM HighProfitItems hp
WHERE hp.profit_rank <= 10
ORDER BY hp.total_net_profit DESC;