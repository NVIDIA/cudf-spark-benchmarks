WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS SalesRank
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE i.i_current_price > 0
      AND ws.ws_sold_date_sk BETWEEN 2458674 AND 2459050 
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status
    FROM customer_demographics cd
    WHERE cd.cd_credit_rating IN ('A', 'B')
),
SalesSummary AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS TotalSales,
        COUNT(DISTINCT ws.ws_order_number) AS OrderCount
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2458674 AND 2459050
    GROUP BY c.c_customer_sk
),
TopCustomers AS (
    SELECT 
        ss.c_customer_sk,
        ss.TotalSales,
        ss.OrderCount,
        ROW_NUMBER() OVER (ORDER BY ss.TotalSales DESC) AS Rank
    FROM SalesSummary ss
)
SELECT 
    TC.Rank,
    TC.c_customer_sk,
    TC.TotalSales,
    TC.OrderCount,
    CD.cd_gender,
    CD.cd_marital_status
FROM TopCustomers TC
JOIN CustomerDemographics CD ON TC.c_customer_sk = CD.cd_demo_sk
WHERE TC.Rank <= 100
ORDER BY TC.TotalSales DESC;