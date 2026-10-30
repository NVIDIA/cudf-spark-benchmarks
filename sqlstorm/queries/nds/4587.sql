
WITH RankedSales AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS SalesRank
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk IN (
        SELECT d_date_sk
        FROM date_dim
        WHERE d_year = 2001 AND d_moy IN (6, 7, 8)  
    )
),
CustomerReturnStats AS (
    SELECT
        wr.wr_returning_customer_sk,
        COUNT(wr.wr_return_quantity) AS TotalReturns,
        SUM(wr.wr_return_amt) AS TotalReturnAmount,
        AVG(wr.wr_return_quantity) AS AvgReturnQty
    FROM web_returns wr
    WHERE wr.wr_returned_date_sk IN (
        SELECT d_date_sk
        FROM date_dim
        WHERE d_year = 2001 AND d_moy IN (6, 7, 8)
    )
    GROUP BY wr.wr_returning_customer_sk
),
AggregateSales AS (
    SELECT
        COALESCE(ct.c_customer_sk, 0) AS CustomerID,
        SUM(COALESCE(rs.ws_net_paid, 0)) AS TotalNetPaid,
        SUM(COALESCE(cs.cs_net_paid, 0)) AS TotalCatalogNetPaid,
        SUM(COALESCE(ss.ss_net_paid, 0)) AS TotalStoreNetPaid
    FROM customer ct
    LEFT JOIN RankedSales rs ON ct.c_customer_sk = rs.ws_item_sk
    LEFT JOIN catalog_sales cs ON ct.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON ct.c_customer_sk = ss.ss_customer_sk
    WHERE ct.c_birth_country IS NULL OR ct.c_birth_country = 'USA'
    GROUP BY ct.c_customer_sk
)
SELECT
    asls.CustomerID,
    asls.TotalNetPaid,
    asls.TotalCatalogNetPaid,
    asls.TotalStoreNetPaid,
    crs.TotalReturns,
    crs.TotalReturnAmount,
    crs.AvgReturnQty
FROM AggregateSales asls
LEFT JOIN CustomerReturnStats crs ON asls.CustomerID = crs.wr_returning_customer_sk
WHERE asls.TotalNetPaid > 1000
ORDER BY asls.TotalNetPaid DESC;
