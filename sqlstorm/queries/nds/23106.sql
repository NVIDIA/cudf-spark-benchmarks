
WITH  AddressCTE AS (
    SELECT ca_address_sk, 
           ca_city, 
           ca_state, 
           ca_zip, 
           ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY ca_city) AS cte_row 
    FROM customer_address
    WHERE ca_state IS NOT NULL
),  
CustomerDetails AS (
    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name, 
           cd.cd_gender, 
           cd.cd_marital_status, 
           cd.cd_dep_count,
           cd.cd_purchase_estimate 
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), 
SalesData AS (
    SELECT ws.ws_sold_date_sk, 
           ws.ws_item_sk, 
           SUM(ws.ws_quantity) AS total_quantity, 
           AVG(ws.ws_net_profit) AS avg_net_profit 
    FROM web_sales ws
    GROUP BY ws.ws_sold_date_sk, ws.ws_item_sk
), 
PastSales AS (
    SELECT cs_item_sk, 
           SUM(cs_quantity) AS historical_quantity 
    FROM catalog_sales 
    WHERE cs_sold_date_sk < (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY cs_item_sk
),
FilteredSales AS (
    SELECT s.ss_item_sk, 
           s.ss_quantity, 
           s.ss_net_profit,
           COALESCE(h.historical_quantity, 0) AS historical_quantity,
           CASE WHEN s.ss_net_profit > 100 THEN 'High Profit' 
                WHEN s.ss_net_profit BETWEEN 50 AND 100 THEN 'Moderate Profit' 
                ELSE 'Low Profit' END AS profit_category 
    FROM store_sales s
    LEFT JOIN PastSales h ON s.ss_item_sk = h.cs_item_sk
), 
RankedSales AS (
    SELECT fs.ss_item_sk, 
           fs.ss_quantity, 
           fs.ss_net_profit, 
           fs.historical_quantity,
           fs.profit_category,
           RANK() OVER (PARTITION BY fs.profit_category ORDER BY fs.ss_net_profit DESC) AS sales_rank 
    FROM FilteredSales fs
)
SELECT addr.cte_row, 
       addr.ca_city, 
       addr.ca_state, 
       cust.c_first_name, 
       cust.c_last_name, 
       sales.sales_rank,
       sales.profit_category, 
       CASE 
           WHEN sales.historical_quantity > 0 THEN sales.ss_quantity / sales.historical_quantity 
           ELSE NULL 
       END AS sales_growth_ratio
FROM AddressCTE addr
JOIN CustomerDetails cust ON cust.c_customer_sk IN (
    SELECT DISTINCT cs_bill_customer_sk 
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2023
)
LEFT JOIN RankedSales sales ON sales.ss_item_sk IN (
    SELECT DISTINCT ss_item_sk 
    FROM store_sales 
    WHERE ss_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim)
)
ORDER BY addr.ca_city, sales.sales_rank;
