
SELECT SUM(ss_net_profit) AS total_net_profit
FROM store_sales
WHERE ss_sold_date_sk BETWEEN 20230101 AND 20231231;
