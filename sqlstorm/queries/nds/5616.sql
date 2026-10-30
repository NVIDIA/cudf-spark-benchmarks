
WITH SalesSummary AS (
    SELECT 
        d.d_year AS SalesYear,
        d.d_month_seq AS SalesMonth,
        SUM(ws_ext_sales_price) AS TotalSales,
        AVG(ws_net_paid) AS AverageNetPaid,
        COUNT(DISTINCT ws_order_number) AS TotalOrders,
        COUNT(DISTINCT ws_ship_customer_sk) AS UniqueCustomers
    FROM web_sales
    JOIN date_dim d ON ws_sold_date_sk = d.d_date_sk
    JOIN customer c ON ws_ship_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN ship_mode sm ON ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_year BETWEEN 2021 AND 2023
    AND cd.cd_gender = 'F'
    AND cd.cd_marital_status = 'M'
    GROUP BY d.d_year, d.d_month_seq
),
ReturnsSummary AS (
    SELECT 
        d.d_year AS ReturnYear,
        d.d_month_seq AS ReturnMonth,
        SUM(wr_return_amt) AS TotalReturns,
        AVG(wr_return_ship_cost) AS AverageReturnShipping,
        COUNT(DISTINCT wr_order_number) AS TotalReturnedOrders
    FROM web_returns
    JOIN date_dim d ON wr_returned_date_sk = d.d_date_sk
    GROUP BY d.d_year, d.d_month_seq
)
SELECT 
    ss.SalesYear, 
    ss.SalesMonth,
    ss.TotalSales,
    ss.AverageNetPaid,
    ss.TotalOrders,
    ss.UniqueCustomers,
    COALESCE(rs.TotalReturns, 0) AS TotalReturns,
    COALESCE(rs.AverageReturnShipping, 0) AS AverageReturnShipping,
    COALESCE(rs.TotalReturnedOrders, 0) AS TotalReturnedOrders
FROM SalesSummary ss
LEFT JOIN ReturnsSummary rs ON ss.SalesYear = rs.ReturnYear AND ss.SalesMonth = rs.ReturnMonth
ORDER BY SalesYear, SalesMonth;
