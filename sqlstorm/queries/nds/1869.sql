
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM web_sales
    GROUP BY ws_item_sk
),
top_items AS (
    SELECT 
        ri.ws_item_sk,
        ri.total_sales,
        i.i_item_desc,
        i.i_brand,
        i.i_category
    FROM ranked_sales ri
    JOIN item i ON ri.ws_item_sk = i.i_item_sk
    WHERE ri.sales_rank <= 10
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        (
            SELECT COUNT(*)
            FROM store_returns sr
            WHERE sr.sr_customer_sk = c.c_customer_sk
        ) AS total_returns,
        (
            SELECT SUM(sr_return_amt_inc_tax)
            FROM store_returns
            WHERE sr_customer_sk = c.c_customer_sk
        ) AS total_returned_amount
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    ci.c_customer_sk,
    ci.cd_gender,
    ci.cd_marital_status,
    ti.i_category,
    ti.i_item_desc,
    ti.total_sales,
    ci.total_returns,
    COALESCE(ci.total_returned_amount, 0) AS adjusted_total_returned_amount,
    CASE 
        WHEN ci.total_returned_amount IS NULL THEN 'No Returns'
        ELSE 'Returned'
    END AS return_status
FROM customer_info ci
JOIN top_items ti ON ci.c_customer_sk = ti.ws_item_sk
ORDER BY ti.total_sales DESC;
