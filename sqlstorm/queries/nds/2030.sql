
WITH ranked_sales AS (
    SELECT 
        ws_bill_customer_sk, 
        ws_item_sk, 
        ws_quantity, 
        ws_ext_sales_price, 
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY ws_ext_sales_price DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT max(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 AND (SELECT max(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
total_sales AS (
    SELECT 
        ws_bill_customer_sk, 
        SUM(ws_ext_sales_price) AS total_sales_amount
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY total_sales_amount DESC) as rank_gender
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        total_sales ts ON c.c_customer_sk = ts.ws_bill_customer_sk
    WHERE 
        cd.cd_marital_status = 'M'
    AND 
        ts.total_sales_amount > 500
)
SELECT 
    ci.c_first_name, 
    ci.c_last_name, 
    COALESCE(rb.item_count, 0) AS return_item_count,
    CASE 
        WHEN ci.rank_gender <= 10 THEN 'Top Customer'
        ELSE 'Regular Customer'
    END AS customer_status
FROM 
    customer_info ci
LEFT JOIN (
    SELECT 
        wr_returning_customer_sk AS customer_sk, 
        COUNT(wr_item_sk) AS item_count
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
) rb ON ci.c_customer_sk = rb.customer_sk
WHERE 
    ci.rank_gender <= 10
ORDER BY 
    ci.rank_gender;
