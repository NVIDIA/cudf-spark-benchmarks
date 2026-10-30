
WITH RankedSales AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS PriceRank,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_quantity DESC) AS QuantityRank
    FROM web_sales AS ws
    JOIN item AS i ON ws.ws_item_sk = i.i_item_sk
    WHERE i.i_current_price BETWEEN 10 AND 100
      AND i.i_formulation IS NOT NULL
), FilteredSales AS (
    SELECT 
        RS.ws_sold_date_sk,
        RS.ws_item_sk,
        RS.ws_sales_price,
        RS.ws_quantity
    FROM RankedSales AS RS
    WHERE (RS.PriceRank = 1 OR RS.QuantityRank <= 3)
      AND (RS.ws_quantity IS NOT NULL AND RS.ws_sales_price IS NOT NULL)
), AggregateSales AS (
    SELECT 
        ws.ws_sold_date_sk,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS TotalSales
    FROM FilteredSales AS ws
    GROUP BY ws.ws_sold_date_sk
), ExternalSales AS (
    SELECT 
        ds.d_year,
        CONCAT('Q', (ds.d_month_seq - 1) / 3 + 1) AS Quarter,
        COALESCE(SUM(asales.TotalSales), 0) AS TotalSalesByQuarter
    FROM date_dim AS ds
    LEFT JOIN AggregateSales AS asales ON ds.d_date_sk = asales.ws_sold_date_sk
    GROUP BY ds.d_year, Quarter
    HAVING ds.d_year IS NOT NULL
)
SELECT 
    es.d_year,
    es.Quarter,
    es.TotalSalesByQuarter,
    CASE 
        WHEN es.TotalSalesByQuarter > 10000 THEN 'High'
        WHEN es.TotalSalesByQuarter BETWEEN 5000 AND 10000 THEN 'Medium'
        ELSE 'Low' 
    END AS SalesCategory
FROM ExternalSales AS es
WHERE es.TotalSalesByQuarter <> (SELECT AVG(TotalSalesByQuarter) FROM ExternalSales) 
ORDER BY es.d_year, es.TotalSalesByQuarter DESC;
