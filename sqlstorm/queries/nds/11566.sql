
SELECT SUM(ss_net_profit) AS total_net_profit, COUNT(DISTINCT ss_ticket_number) AS total_transactions
FROM store_sales
WHERE ss_sold_date_sk BETWEEN 1 AND 365
GROUP BY ss_store_sk
ORDER BY total_net_profit DESC
LIMIT 10;
