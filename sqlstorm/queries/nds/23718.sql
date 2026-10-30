WITH RecursiveCTE AS (
    SELECT 
        ca_address_sk, 
        ca_state, 
        ca_city, 
        COUNT(*) OVER (PARTITION BY ca_state ORDER BY ca_city) AS city_count,
        ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY ca_city) AS row_num
    FROM 
        customer_address
    WHERE 
        ca_state IS NOT NULL
),
SalesSummary AS (
    SELECT 
        ws_bill_addr_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim WHERE d_current_month = 'Y')
    GROUP BY 
        ws_bill_addr_sk
),
ItemDetail AS (
    SELECT 
        i_item_sk,
        i_current_price,
        i_item_desc,
        CASE 
            WHEN i_current_price IS NULL THEN 0
            ELSE i_current_price * 1.1 
        END AS adjusted_price
    FROM 
        item
    WHERE 
        i_rec_start_date <= cast('2002-10-01' as date) AND (i_rec_end_date IS NULL OR i_rec_end_date > cast('2002-10-01' as date))
),
ReturnSummary AS (
    SELECT
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt) AS total_return_amt,
        SUM(sr_return_tax) AS total_return_tax
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
)
SELECT 
    ca.ca_address_sk,
    ca.ca_city,
    ca.ca_state,
    ss.total_sales,
    ss.order_count,
    COALESCE(rs.total_returns, 0) AS total_returns,
    COALESCE(rs.total_return_amt, 0) AS total_return_amt,
    COALESCE(rs.total_return_tax, 0) AS total_return_tax,
    SUM(id.adjusted_price) AS adjusted_price_sum
FROM 
    RecursiveCTE ca
LEFT JOIN 
    SalesSummary ss ON ss.ws_bill_addr_sk = ca.ca_address_sk
LEFT JOIN 
    ReturnSummary rs ON rs.sr_item_sk = ca.ca_address_sk 
LEFT JOIN 
    ItemDetail id ON id.i_item_sk = rs.sr_item_sk
WHERE 
    ca.city_count > 5
    AND (COALESCE(ss.total_sales, 0) > 1000 OR rs.total_return_amt IS NULL)
GROUP BY 
    ca.ca_address_sk, 
    ca.ca_city, 
    ca.ca_state, 
    ss.total_sales, 
    ss.order_count, 
    rs.total_returns, 
    rs.total_return_amt, 
    rs.total_return_tax
HAVING 
    SUM(id.adjusted_price) < 5000
ORDER BY 
    ca.ca_state, 
    ca.ca_city
LIMIT 50;