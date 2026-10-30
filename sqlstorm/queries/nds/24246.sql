
WITH RankedSales AS (
    SELECT 
        s.ss_item_sk,
        s.ss_sales_price,
        s.ss_quantity,
        ROW_NUMBER() OVER (PARTITION BY s.ss_item_sk ORDER BY s.ss_sales_price DESC) AS price_rank,
        SUM(s.ss_net_profit) OVER (PARTITION BY s.ss_item_sk) AS total_net_profit
    FROM 
        store_sales s
    WHERE 
        s.ss_sold_date_sk BETWEEN (SELECT MIN(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023) 
        AND (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
),
CustomerAddress AS (
    SELECT
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        CASE 
            WHEN ca.ca_state IS NULL THEN 'Unknown State'
            ELSE ca.ca_state
        END AS state_with_default
    FROM 
        customer_address ca
    WHERE 
        ca.ca_city IN (SELECT DISTINCT c.c_first_name FROM customer c WHERE c.c_last_name LIKE 'Smith%')
),
FilteredSales AS (
    SELECT 
        rs.ss_item_sk,
        rs.ss_sales_price,
        rs.ss_quantity,
        ca.state_with_default,
        CASE 
            WHEN rs.price_rank = 1 THEN 'Top Price'
            WHEN rs.price_rank = 2 THEN 'Second Price'
            ELSE 'Other Prices'
        END AS price_group
    FROM 
        RankedSales rs
    LEFT JOIN 
        CustomerAddress ca ON rs.ss_item_sk = ca.ca_address_sk
    WHERE 
        rs.total_net_profit > 1000
),
FinalResults AS (
    SELECT 
        fs.ss_item_sk,
        fs.ss_sales_price,
        fs.ss_quantity,
        fs.state_with_default,
        fs.price_group,
        COALESCE(SUM(fs.ss_sales_price * fs.ss_quantity), 0) AS total_sales_amount
    FROM 
        FilteredSales fs
    GROUP BY 
        fs.ss_item_sk, fs.ss_sales_price, fs.ss_quantity, fs.state_with_default, fs.price_group
)
SELECT 
    fr.ss_item_sk,
    fr.ss_sales_price,
    fr.ss_quantity,
    fr.state_with_default,
    fr.price_group,
    fr.total_sales_amount
FROM 
    FinalResults fr
ORDER BY 
    total_sales_amount DESC, fr.ss_quantity ASC
LIMIT 100
OFFSET 10;
