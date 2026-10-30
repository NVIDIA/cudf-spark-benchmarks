
WITH  SalesCTE AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER(PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS rank
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk >= (SELECT MIN(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2022)
      AND ws.ws_sold_date_sk <= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2022)
    GROUP BY ws.ws_item_sk
),
BestSellingItems AS (
    SELECT *
    FROM SalesCTE
    WHERE rank <= 10
),
CustomerSegmentation AS (
    SELECT
        cd.cd_gender,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender
),
StoreSummary AS (
    SELECT
        s.s_store_id,
        SUM(ss.ss_sales_price) AS total_store_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
        AVG(ss.ss_sales_price) AS avg_transaction_value,
        SUM(ss.ss_ext_discount_amt) AS total_discounts
    FROM store s
    LEFT JOIN store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY s.s_store_id
)
SELECT
    bsi.ws_item_sk,
    bsi.total_sales AS total_item_sales,
    cs.cd_gender,
    cs.total_sales AS gender_sales,
    ss.s_store_id,
    ss.total_store_sales,
    ss.total_transactions,
    ss.avg_transaction_value,
    ss.total_discounts
FROM BestSellingItems bsi
JOIN CustomerSegmentation cs ON bsi.ws_item_sk IN (
    SELECT ws.ws_item_sk
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk IN (SELECT d.d_date_sk FROM date_dim d WHERE d.d_year = 2022)
    GROUP BY ws.ws_item_sk
)
JOIN StoreSummary ss ON (ss.total_store_sales > 1000 OR ss.total_transactions > 50)
ORDER BY bsi.total_sales DESC, cs.total_sales DESC;
