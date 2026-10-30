WITH RankedSales AS (
    SELECT 
        ws_ship_date_sk, 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity, 
        SUM(ws_net_paid) AS total_sales, 
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_quantity) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_ship_date_sk, 
        ws_item_sk
), 
TopProducts AS (
    SELECT 
        r.ws_item_sk, 
        r.total_quantity, 
        r.total_sales
    FROM 
        RankedSales r
    WHERE 
        r.sales_rank = 1
), 
CustomerAnalysis AS (
    SELECT 
        cd_demo_sk, 
        COUNT(DISTINCT c_customer_sk) AS customer_count, 
        SUM(t.total_sales) AS total_sales_per_demo
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        TopProducts t ON c.c_customer_sk = t.ws_item_sk 
    GROUP BY 
        cd_demo_sk
), 
SalesDetail AS (
    SELECT 
        d.d_date,
        SUM(tp.total_sales) AS daily_sales,
        AVG(tp.total_quantity) AS avg_quantity_per_sale,
        COUNT(DISTINCT ca.ca_city) AS unique_cities
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_ship_date_sk
    JOIN 
        TopProducts tp ON ws.ws_item_sk = tp.ws_item_sk
    JOIN 
        customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    GROUP BY 
        d.d_date
)
SELECT 
    d.d_date,
    COALESCE(sd.daily_sales, 0) AS total_daily_sales,
    COALESCE(sd.avg_quantity_per_sale, 0) AS avg_quantity_per_sale,
    COALESCE(sd.unique_cities, 0) AS unique_cities
FROM 
    date_dim d
LEFT JOIN 
    SalesDetail sd ON d.d_date = sd.d_date
WHERE 
    d.d_date BETWEEN '2001-01-01' AND '2001-12-31'
ORDER BY 
    d.d_date;