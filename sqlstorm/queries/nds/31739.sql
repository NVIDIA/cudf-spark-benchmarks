
WITH  MonthlySales AS (
    SELECT 
        d.d_year,
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        web_sales 
    JOIN 
        date_dim d ON ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year
    UNION ALL
    SELECT 
        d.d_year,
        SUM(cs_ext_sales_price) AS total_sales
    FROM 
        catalog_sales 
    JOIN 
        date_dim d ON cs_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year
), RankedSales AS (
    SELECT 
        d_year,
        total_sales,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        MonthlySales
), HighPerformingStores AS (
    SELECT 
        s_store_id,
        s_store_name,
        SUM(ss_net_profit) AS total_profit
    FROM 
        store_sales 
    JOIN 
        store ON ss_store_sk = s_store_sk
    GROUP BY 
        s_store_id, s_store_name
    HAVING 
        SUM(ss_net_profit) > (
            SELECT 
                AVG(total_profit) 
            FROM 
                (SELECT 
                    SUM(ss_net_profit) AS total_profit
                FROM 
                    store_sales 
                GROUP BY 
                    ss_store_sk) AS store_profits
        )
), CustomerAddressCount AS (
    SELECT 
        ca_country,
        COUNT(DISTINCT c_customer_sk) AS customer_count
    FROM 
        customer_address 
    JOIN 
        customer ON ca_address_sk = c_current_addr_sk
    GROUP BY 
        ca_country
)
SELECT 
    hs.s_store_name,
    ms.d_year,
    ms.total_sales,
    hs.total_profit,
    cac.ca_country,
    cac.customer_count
FROM 
    RankedSales ms
JOIN 
    HighPerformingStores hs ON ms.total_sales > 50000
CROSS JOIN 
    CustomerAddressCount cac
WHERE 
    cac.customer_count IS NOT NULL
ORDER BY 
    ms.total_sales DESC, hs.total_profit DESC
LIMIT 100;
