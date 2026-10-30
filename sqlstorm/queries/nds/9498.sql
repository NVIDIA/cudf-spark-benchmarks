
WITH SalesData AS (
    SELECT 
        d.d_year AS SalesYear,
        i.i_category AS ItemCategory,
        SUM(ss.ss_sales_price) AS TotalSales,
        COUNT(DISTINCT ss.ss_ticket_number) AS TotalTransactions,
        AVG(ss.ss_net_profit) AS AverageProfit
    FROM 
        store_sales ss
    JOIN 
        date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN 
        item i ON ss.ss_item_sk = i.i_item_sk
    WHERE 
        d.d_year BETWEEN 1998 AND 2001
    GROUP BY 
        d.d_year, i.i_category
), CustomerData AS (
    SELECT 
        cd.cd_gender AS Gender,
        COUNT(DISTINCT c.c_customer_sk) AS TotalCustomers,
        AVG(cd.cd_purchase_estimate) AS AvgPurchaseEstimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_marital_status = 'M'
    GROUP BY 
        cd.cd_gender
)
SELECT 
    sd.SalesYear,
    sd.ItemCategory,
    sd.TotalSales,
    sd.TotalTransactions,
    sd.AverageProfit,
    cd.Gender,
    cd.TotalCustomers,
    cd.AvgPurchaseEstimate
FROM 
    SalesData sd
JOIN 
    CustomerData cd ON sd.SalesYear = EXTRACT(YEAR FROM CAST('2002-10-01' AS DATE))
ORDER BY 
    sd.SalesYear, sd.TotalSales DESC;
