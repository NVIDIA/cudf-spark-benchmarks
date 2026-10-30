WITH  SalesCTE AS (
    SELECT ss_item_sk, SUM(ss_ext_sales_price) AS total_sales, COUNT(ss_ticket_number) AS total_transactions
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN (
        SELECT d_date_sk FROM date_dim WHERE d_date = '2001-01-01'
    ) AND (
        SELECT d_date_sk FROM date_dim WHERE d_date = '2001-12-31'
    )
    GROUP BY ss_item_sk
    
    UNION ALL
    
    SELECT ss_item_sk, SUM(ss_ext_sales_price) AS total_sales, COUNT(ss_ticket_number) AS total_transactions
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN (
        SELECT d_date_sk FROM date_dim WHERE d_date = '2002-01-01'
    ) AND (
        SELECT d_date_sk FROM date_dim WHERE d_date = '2002-12-31'
    )
    GROUP BY ss_item_sk
),
TotalSales AS (
    SELECT item.i_item_sk, 
           item.i_item_desc, 
           COALESCE(SUM(SalesCTE.total_sales), 0) AS yearly_sales,
           COALESCE(SUM(SalesCTE.total_transactions), 0) AS total_units_sold,
           ROW_NUMBER() OVER (ORDER BY COALESCE(SUM(SalesCTE.total_sales), 0) DESC) AS sales_rank
    FROM item
    LEFT JOIN SalesCTE ON item.i_item_sk = SalesCTE.ss_item_sk
    GROUP BY item.i_item_sk, item.i_item_desc
)
SELECT t.yearly_sales, 
       t.total_units_sold, 
       CONCAT(t.i_item_desc, ' (Rank: ', t.sales_rank, ')') AS item_details
FROM TotalSales t
WHERE t.yearly_sales > 10000
ORDER BY t.yearly_sales DESC
LIMIT 10;