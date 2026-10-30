
WITH SalesSummary AS (
    SELECT 
        w.w_warehouse_id AS WarehouseID,
        d.d_year AS SalesYear,
        SUM(ss.ss_ext_sales_price) AS TotalSales,
        COUNT(DISTINCT ss.ss_ticket_number) AS TotalTransactions,
        AVG(ss.ss_sales_price) AS AvgSalesPrice,
        AVG(ss.ss_net_profit) AS AvgNetProfit
    FROM 
        store_sales ss
    JOIN 
        store s ON ss.ss_store_sk = s.s_store_sk
    JOIN 
        warehouse w ON s.s_company_id = w.w_warehouse_sk
    JOIN 
        date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2021 AND 2023
    GROUP BY 
        w.w_warehouse_id, d.d_year
),
CustomerSegment AS (
    SELECT 
        cd.cd_gender AS Gender,
        CASE 
            WHEN cd.cd_purchase_estimate < 1000 THEN 'Low'
            WHEN cd.cd_purchase_estimate BETWEEN 1000 AND 5000 THEN 'Medium'
            ELSE 'High'
        END AS PurchaseEstimateSegment,
        COUNT(DISTINCT c.c_customer_id) AS CustomerCount
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, PurchaseEstimateSegment
)
SELECT 
    ss.WarehouseID,
    ss.SalesYear,
    ss.TotalSales,
    ss.TotalTransactions,
    ss.AvgSalesPrice,
    ss.AvgNetProfit,
    cs.Gender,
    cs.PurchaseEstimateSegment,
    cs.CustomerCount
FROM 
    SalesSummary ss
JOIN 
    CustomerSegment cs ON ss.WarehouseID = (SELECT MIN(s.w_warehouse_id) FROM warehouse s)
ORDER BY 
    ss.SalesYear, ss.TotalSales DESC;
