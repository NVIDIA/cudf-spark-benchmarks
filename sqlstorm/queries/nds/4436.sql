
WITH RankedSales AS (
    SELECT 
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity_sold,
        SUM(cs_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY cs_item_sk ORDER BY SUM(cs_quantity) DESC) AS rank_quantity
    FROM catalog_sales
    GROUP BY cs_item_sk
),
CustomerReturns AS (
    SELECT 
        cr_item_sk,
        COUNT(cr_order_number) AS total_returns,
        SUM(cr_return_amount) AS total_return_amt,
        SUM(cr_return_tax) AS total_return_tax
    FROM catalog_returns
    GROUP BY cr_item_sk
),
HighValueCustomers AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_credit_rating,
        SUM(ws.ws_net_paid) AS total_spent
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_credit_rating
    HAVING SUM(ws.ws_net_paid) > 5000
),
CombinedReturns AS (
    SELECT 
        RS.cs_item_sk,
        COALESCE(CR.total_returns, 0) AS total_returns,
        COALESCE(CR.total_return_amt, 0) AS total_return_amt,
        COALESCE(CR.total_return_tax, 0) AS total_return_tax,
        RS.total_quantity_sold,
        RS.total_sales
    FROM RankedSales RS
    LEFT JOIN CustomerReturns CR ON RS.cs_item_sk = CR.cr_item_sk
),
FinalReport AS (
    SELECT 
        C.cs_item_sk,
        C.total_quantity_sold,
        C.total_sales,
        C.total_returns,
        C.total_return_amt,
        C.total_return_tax,
        CASE 
            WHEN C.total_sales - C.total_return_amt < 0 THEN 'Loss'
            ELSE 'Profit'
        END AS profit_loss_status,
        HC.c_customer_sk,
        HC.c_first_name,
        HC.c_last_name,
        HC.total_spent
    FROM CombinedReturns C
    LEFT JOIN HighValueCustomers HC ON C.total_sales > 1000
    ORDER BY C.total_quantity_sold DESC
)
SELECT 
    item.i_item_id,
    item.i_item_desc,
    FR.total_sales,
    FR.total_returns,
    FR.profit_loss_status,
    FR.c_first_name,
    FR.c_last_name
FROM FinalReport FR
JOIN item ON FR.cs_item_sk = item.i_item_sk
WHERE FR.profit_loss_status = 'Profit' OR FR.total_returns > 10
ORDER BY FR.total_sales DESC, FR.total_returns DESC
LIMIT 100;
