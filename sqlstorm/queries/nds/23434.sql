
WITH  Sales_CTE AS (
    SELECT 
        s.ss_sold_date_sk,
        s.ss_item_sk,
        s.ss_sales_price,
        s.ss_quantity,
        s.ss_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY s.ss_item_sk ORDER BY s.ss_sold_date_sk DESC) AS rn
    FROM store_sales s
    WHERE s.ss_quantity IS NOT NULL
), 
Customer_Summary AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(SUM(ws.ws_net_paid), 0) AS total_web_sales,
        COALESCE(SUM(ss.ss_net_paid), 0) AS total_store_sales,
        COALESCE(MAX(ws.ws_net_paid), 0) AS max_web_sale_once,
        CASE 
            WHEN COUNT(tr.tr_month) > 3 THEN 'Frequent Buyer'
            ELSE 'Occasional Buyer'
        END AS buyer_type
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN (
        SELECT DISTINCT d.d_month_seq AS tr_month
        FROM date_dim d
    ) AS tr ON tr.tr_month BETWEEN 1 AND 12
    GROUP BY c.c_customer_sk
), 
Top_Products AS (
    SELECT 
        item.i_item_sk,
        item.i_item_desc,
        SUM(sales.ss_quantity) AS total_quantity_sold,
        RANK() OVER (ORDER BY SUM(sales.ss_quantity) DESC) AS rank
    FROM item
    JOIN store_sales sales ON item.i_item_sk = sales.ss_item_sk
    WHERE sales.ss_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY item.i_item_sk, item.i_item_desc
)
SELECT 
    cs.c_customer_sk,
    cs.total_web_sales,
    cs.total_store_sales,
    cs.max_web_sale_once,
    cs.buyer_type,
    pp.i_item_desc,
    pp.total_quantity_sold
FROM Customer_Summary cs
LEFT JOIN Top_Products pp ON pp.rank <= 10
WHERE cs.total_store_sales > 1000
OR (cs.total_web_sales IS NOT NULL AND cs.total_web_sales > 500)
ORDER BY cs.total_store_sales DESC, cs.total_web_sales DESC;
