
WITH  SalesHierarchy AS (
    SELECT 
        cs_sold_date_sk AS sales_date,
        cs_item_sk,
        SUM(cs_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY cs_item_sk ORDER BY SUM(cs_net_profit) DESC) AS rank
    FROM catalog_sales
    WHERE cs_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY cs_sold_date_sk, cs_item_sk
), ItemDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        COALESCE(sm.sm_type, 'Not Specified') AS shipping_mode,
        ROW_NUMBER() OVER (PARTITION BY i.i_item_sk ORDER BY i.i_item_sk) AS item_rank
    FROM item i
    LEFT JOIN ship_mode sm ON i.i_item_sk = sm.sm_ship_mode_sk
), CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_email_address,
        d.d_year,
        COUNT(s.ss_ticket_number) AS total_sales,
        SUM(s.ss_net_paid) AS total_spent
    FROM customer c
    JOIN store_sales s ON c.c_customer_sk = s.ss_customer_sk
    JOIN date_dim d ON s.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2023
    GROUP BY c.c_customer_sk, c.c_email_address, d.d_year
), HighSpenders AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_email_address,
        ci.total_sales,
        ci.total_spent,
        CASE 
            WHEN ci.total_spent > 1000 THEN 'Gold'
            WHEN ci.total_spent BETWEEN 500 AND 1000 THEN 'Silver'
            ELSE 'Bronze'
        END AS customer_tier
    FROM CustomerInfo ci
    WHERE ci.total_spent > 0
)
SELECT 
    sh.sales_date,
    id.i_item_desc,
    ROUND(SUM(sh.total_profit), 2) AS total_profit,
    hs.c_email_address,
    hs.customer_tier
FROM SalesHierarchy sh
JOIN ItemDetails id ON sh.cs_item_sk = id.i_item_sk
JOIN HighSpenders hs ON hs.c_customer_sk = (SELECT c_customer_sk FROM customer WHERE c_customer_id = 'CUST01234' LIMIT 1)
WHERE sh.rank = 1
GROUP BY sh.sales_date, id.i_item_desc, hs.c_email_address, hs.customer_tier
ORDER BY total_profit DESC
LIMIT 10;
