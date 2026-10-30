
WITH CustomerPurchaseStats AS (
    SELECT c.c_customer_sk,
           c.c_customer_id,
           cd.cd_gender,
           cd.cd_marital_status,
           SUM(ws.ws_net_paid) AS total_spent,
           COUNT(DISTINCT ws.ws_order_number) AS total_orders,
           DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_paid) DESC) AS rank_spent
    FROM customer c
             JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
             JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
             WHERE ws.ws_sold_date_sk BETWEEN 1000 AND 2000
    GROUP BY c.c_customer_sk, c.c_customer_id, cd.cd_gender, cd.cd_marital_status
),
StoreSalesDetails AS (
    SELECT ss.ss_store_sk,
           SUM(ss.ss_net_profit) AS total_store_profit,
           COUNT(ss.ss_ticket_number) AS total_sales_tickets
    FROM store_sales ss
    GROUP BY ss.ss_store_sk
),
ItemSalesDetails AS (
    SELECT i.i_item_sk,
           i.i_item_desc,
           SUM(ws.ws_quantity) AS total_quantity_sold,
           AVG(ws.ws_sales_price) AS avg_sales_price,
           COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM item i
             JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY i.i_item_sk, i.i_item_desc
),
TopStores AS (
    SELECT s.s_store_sk,
           s.s_store_name,
           COALESCE(ssd.total_store_profit, 0) AS total_store_profit
    FROM store s
             LEFT JOIN StoreSalesDetails ssd ON s.s_store_sk = ssd.ss_store_sk
)
SELECT cps.c_customer_id,
       cps.cd_gender,
       cps.cd_marital_status,
       cps.total_spent,
       cps.total_orders,
       ts.s_store_name,
       ts.total_store_profit,
       ids.i_item_desc,
       ids.total_quantity_sold,
       ids.avg_sales_price
FROM CustomerPurchaseStats cps
         JOIN TopStores ts ON cps.c_customer_sk % 10 = ts.s_store_sk % 10
         JOIN ItemSalesDetails ids ON cps.c_customer_sk % 100 = ids.i_item_sk % 100
WHERE cps.rank_spent <= 10
          AND ts.total_store_profit > (
              SELECT AVG(total_store_profit)
              FROM StoreSalesDetails
          )
ORDER BY cps.total_spent DESC, ts.total_store_profit DESC;
