
SELECT SUM(ss_sales_price) AS total_sales, COUNT(ss_ticket_number) AS total_transactions
FROM store_sales
WHERE ss_sold_date_sk BETWEEN 1000 AND 2000;
