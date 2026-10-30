
WITH DateRange AS (
    SELECT D.d_date_sk, D.d_year, D.d_month_seq
    FROM date_dim D
    WHERE D.d_date BETWEEN '2023-01-01' AND '2023-12-31'
),
CustomerStats AS (
    SELECT C.c_customer_sk, 
           C.c_first_name, 
           C.c_last_name, 
           CD.cd_gender, 
           CD.cd_marital_status,
           CD.cd_dep_count,
           COALESCE(SUM(SS.ss_net_profit), 0) AS total_store_profit,
           COALESCE(SUM(WS.ws_net_profit), 0) AS total_web_profit,
           COUNT(DISTINCT SS.ss_ticket_number) AS total_store_sales,
           COUNT(DISTINCT WS.ws_order_number) AS total_web_sales
    FROM customer C
    LEFT JOIN customer_demographics CD ON C.c_current_cdemo_sk = CD.cd_demo_sk
    LEFT JOIN store_sales SS ON C.c_customer_sk = SS.ss_customer_sk 
    LEFT JOIN web_sales WS ON C.c_customer_sk = WS.ws_ship_customer_sk
    GROUP BY C.c_customer_sk, C.c_first_name, C.c_last_name, CD.cd_gender, CD.cd_marital_status, CD.cd_dep_count
),
IncomeLevels AS (
    SELECT HD.hd_demo_sk, 
           IB.ib_income_band_sk, 
           CASE 
               WHEN HD.hd_buy_potential = 'High' THEN 'High Income'
               WHEN HD.hd_buy_potential = 'Medium' THEN 'Medium Income'
               ELSE 'Low Income'
           END AS income_level
    FROM household_demographics HD
    JOIN income_band IB ON HD.hd_income_band_sk = IB.ib_income_band_sk
),
SalesSummary AS (
    SELECT C.c_customer_sk,
           D.d_year,
           SUM(SS.ss_net_profit) AS total_store_profit,
           SUM(WS.ws_net_profit) AS total_web_profit,
           SUM(SS.ss_quantity) AS total_store_quantity,
           SUM(WS.ws_quantity) AS total_web_quantity
    FROM CustomerStats C
    JOIN store_sales SS ON C.c_customer_sk = SS.ss_customer_sk
    JOIN web_sales WS ON C.c_customer_sk = WS.ws_ship_customer_sk
    JOIN DateRange D ON SS.ss_sold_date_sk = D.d_date_sk OR WS.ws_sold_date_sk = D.d_date_sk
    GROUP BY C.c_customer_sk, D.d_year
)
SELECT S.c_customer_sk,
       S.total_store_profit,
       S.total_web_profit,
       I.income_level,
       S.total_store_quantity,
       S.total_web_quantity,
       CASE
           WHEN S.total_store_profit > S.total_web_profit THEN 'Store Sales Higher'
           ELSE 'Web Sales Higher or Equal'
       END AS sales_comparison
FROM SalesSummary S
JOIN IncomeLevels I ON S.c_customer_sk = I.hd_demo_sk
WHERE S.total_store_profit > 1000 OR S.total_web_profit > 1000
ORDER BY S.total_store_profit DESC, S.total_web_profit DESC;
