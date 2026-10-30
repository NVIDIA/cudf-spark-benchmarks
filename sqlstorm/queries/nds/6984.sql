
WITH SalesData AS (
    SELECT
        ws.ws_item_sk AS ItemID,
        ws.ws_quantity AS QuantitySold,
        ws.ws_sales_price AS SalesPrice,
        ws.ws_net_paid AS NetProfit,
        d.d_year AS SalesYear,
        d.d_month_seq AS SalesMonth
    FROM
        web_sales ws
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year BETWEEN 2021 AND 2023
),
CustomerSales AS (
    SELECT
        c.c_customer_sk AS CustomerID,
        SUM(sd.NetProfit) AS TotalNetProfit,
        COUNT(sd.ItemID) AS TotalItemsSold,
        AVG(sd.SalesPrice) AS AvgSalePrice
    FROM
        SalesData sd
    JOIN
        customer c ON sd.ItemID = c.c_current_addr_sk
    GROUP BY
        c.c_customer_sk
),
TopCustomers AS (
    SELECT
        CustomerID,
        TotalNetProfit,
        TotalItemsSold,
        AvgSalePrice,
        ROW_NUMBER() OVER (ORDER BY TotalNetProfit DESC) AS Rank
    FROM
        CustomerSales
)
SELECT
    CustomerID,
    TotalNetProfit,
    TotalItemsSold,
    AvgSalePrice
FROM
    TopCustomers
WHERE
    Rank <= 10
ORDER BY
    TotalNetProfit DESC;
