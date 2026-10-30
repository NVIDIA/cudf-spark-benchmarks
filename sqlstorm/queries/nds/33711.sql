
WITH  Sales_CTE AS (
    SELECT 
        ws_date.d_year, 
        ws_item_sk, 
        SUM(ws_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM web_sales 
    INNER JOIN date_dim ws_date ON web_sales.ws_sold_date_sk = ws_date.d_date_sk
    GROUP BY ws_date.d_year, ws_item_sk
), Ranked_Sales AS (
    SELECT 
        d_year, 
        ws_item_sk, 
        total_sales,
        sales_rank
    FROM Sales_CTE
    WHERE sales_rank <= 10
), Item_Info AS (
    SELECT 
        i_item_sk, 
        i_item_desc, 
        i_current_price,
        COALESCE(NULLIF(i_current_price, 0), 1) AS adjusted_price
    FROM item
), Customer_Info AS (
    SELECT 
        c_customer_sk, 
        cd_demo_sk, 
        cd_gender,
        cd_marital_status,
        cd_credit_rating
    FROM customer 
    LEFT JOIN customer_demographics ON customer.c_current_cdemo_sk = customer_demographics.cd_demo_sk
), Store_Sales_Totals AS (
    SELECT 
        ss_item_sk,
        SUM(ss_ext_sales_price) AS store_total_sales,
        COUNT(ss_ticket_number) AS num_transactions
    FROM store_sales
    GROUP BY ss_item_sk
)
SELECT 
    II.i_item_desc,
    II.i_current_price,
    COALESCE(S.total_sales, 0) AS web_sales,
    COALESCE(SS.store_total_sales, 0) AS store_sales,
    C.cd_gender,
    C.cd_marital_status,
    CASE 
        WHEN C.cd_credit_rating = 'Good' THEN 'High Value'
        WHEN C.cd_credit_rating = 'Bad' THEN 'Low Value'
        ELSE 'Medium Value'
    END AS credit_value_category
FROM Item_Info II
LEFT JOIN Ranked_Sales S ON II.i_item_sk = S.ws_item_sk
LEFT JOIN Store_Sales_Totals SS ON II.i_item_sk = SS.ss_item_sk
LEFT JOIN Customer_Info C ON S.total_sales = C.cd_demo_sk
WHERE (II.i_current_price * 0.8) < COALESCE(S.total_sales, 0) 
      AND C.cd_gender IN ('M', 'F')
ORDER BY II.i_item_desc;
