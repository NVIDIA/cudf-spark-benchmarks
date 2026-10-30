
WITH  Sales_CTE AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_net_paid,
        ws_sold_date_sk,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS rnk
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT d_date_sk FROM date_dim WHERE d_date = DATE '2002-10-01' - INTERVAL '30 days')
    GROUP BY ws_item_sk, ws_sold_date_sk
),
Top_Sales AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        sales.total_quantity,
        sales.total_net_paid,
        sales.ws_sold_date_sk
    FROM Sales_CTE sales
    JOIN item ON sales.ws_item_sk = item.i_item_sk
    WHERE sales.rnk <= 10
),
Monthly_Sales AS (
    SELECT 
        d_year,
        SUM(total_net_paid) AS monthly_net_sales
    FROM (
        SELECT 
            dt.d_year,
            ts.total_net_paid,
            ts.ws_sold_date_sk
        FROM Top_Sales ts
        JOIN date_dim dt ON dt.d_date_sk = ts.ws_sold_date_sk
    ) AS Monthly_Data
    GROUP BY d_year
),
Customer_Info AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        d.cd_marital_status,
        d.cd_gender,
        u.uber_receive AS is_big_spender
    FROM customer c
    LEFT JOIN customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
    LEFT JOIN (
        SELECT 
            ws_bill_customer_sk,
            CASE 
                WHEN SUM(ws_net_paid) > 1000 THEN 'Yes'
                ELSE 'No' 
            END AS uber_receive
        FROM web_sales
        GROUP BY ws_bill_customer_sk
    ) u ON c.c_customer_sk = u.ws_bill_customer_sk
)
SELECT 
    ci.c_customer_id,
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_marital_status,
    ci.cd_gender,
    ms.monthly_net_sales
FROM Customer_Info ci
INNER JOIN Monthly_Sales ms ON ci.c_customer_id = CAST(ms.d_year AS STRING)
WHERE 
    ci.cd_marital_status IS NOT NULL 
    AND ci.cd_gender = 'F'
ORDER BY ms.monthly_net_sales DESC
LIMIT 20;
