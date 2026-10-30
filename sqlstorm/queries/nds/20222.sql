
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_sales_price * ws.ws_quantity AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS rn
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 1 AND 365
        AND i.i_current_price IS NOT NULL
),
BestSellingItems AS (
    SELECT 
        r.ws_item_sk,
        SUM(r.total_sales) AS total_sales
    FROM 
        RankedSales r
    WHERE 
        r.rn = 1
    GROUP BY 
        r.ws_item_sk
),
CustomerAddressInfo AS (
    SELECT 
        ca.ca_address_sk, 
        ca.ca_country, 
        COUNT(c.c_customer_sk) AS customer_count
    FROM 
        customer c
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        ca.ca_address_sk, ca.ca_country
),
SalesByCountry AS (
    SELECT 
        ai.ca_country,
        COALESCE(SUM(bs.total_sales), 0) AS total_sales_by_country
    FROM 
        CustomerAddressInfo ai
    LEFT JOIN 
        BestSellingItems bs ON ai.customer_count > 10 
    GROUP BY 
        ai.ca_country
),
SalesComparison AS (
    SELECT 
        sc.ca_country,
        sc.total_sales_by_country,
        ROW_NUMBER() OVER (ORDER BY sc.total_sales_by_country DESC) AS sales_rank
    FROM 
        SalesByCountry sc
)
SELECT 
    s.ca_country,
    CASE 
        WHEN s.sales_rank <= 10 THEN 'Top 10 Countries'
        ELSE 'Other Countries'
    END AS tier,
    s.total_sales_by_country
FROM 
    SalesComparison s
WHERE 
    s.total_sales_by_country > (SELECT AVG(total_sales_by_country) FROM SalesByCountry)
ORDER BY 
    s.total_sales_by_country DESC;
