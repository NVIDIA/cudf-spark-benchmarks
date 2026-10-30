
WITH RankedSales AS (
    SELECT
        ws_bill_customer_sk,
        ws_item_sk,
        ws_quantity,
        SUM(ws_net_profit) OVER (PARTITION BY ws_bill_customer_sk ORDER BY ws_quantity DESC) AS cumulative_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY ws_quantity DESC) AS sales_rank
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
HighValueCustomers AS (
    SELECT
        c_customer_sk,
        c_first_name,
        c_last_name,
        cd_gender,
        cd_marital_status,
        SUM(cumulative_profit) AS total_profit
    FROM RankedSales
    JOIN customer ON RankedSales.ws_bill_customer_sk = customer.c_customer_sk
    JOIN customer_demographics ON customer.c_current_cdemo_sk = customer_demographics.cd_demo_sk
    WHERE cumulative_profit > 5000
    GROUP BY c_customer_sk, c_first_name, c_last_name, cd_gender, cd_marital_status
),
TopItems AS (
    SELECT
        ws_item_sk,
        COUNT(*) AS sales_count
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY ws_item_sk
    HAVING COUNT(*) > 100
),
PotentialReturns AS (
    SELECT
        wr_returning_customer_sk,
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returned
    FROM web_returns
    WHERE wr_returned_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY wr_returning_customer_sk, wr_item_sk
),
FinalReport AS (
    SELECT
        hvc.c_customer_sk,
        CONCAT(hvc.c_first_name, ' ', hvc.c_last_name) AS customer_name,
        hvc.cd_gender,
        hvc.cd_marital_status,
        ti.ws_item_sk,
        ti.sales_count,
        COALESCE(pr.total_returned, 0) AS total_returns,
        hvc.total_profit
    FROM HighValueCustomers hvc
    JOIN TopItems ti ON hvc.c_customer_sk IN (SELECT ws_bill_customer_sk FROM web_sales WHERE ws_item_sk = ti.ws_item_sk)
    LEFT JOIN PotentialReturns pr ON hvc.c_customer_sk = pr.wr_returning_customer_sk AND ti.ws_item_sk = pr.wr_item_sk
)
SELECT 
    customer_name,
    cd_gender,
    cd_marital_status,
    SUM(sales_count) AS total_items_sold,
    SUM(total_returns) AS total_returns,
    SUM(total_profit) AS total_profit
FROM FinalReport
GROUP BY customer_name, cd_gender, cd_marital_status
ORDER BY total_profit DESC
LIMIT 10;
