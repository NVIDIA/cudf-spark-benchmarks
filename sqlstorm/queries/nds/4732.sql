WITH RankedReturns AS (
    SELECT 
        sr_item_sk,
        sr_return_quantity,
        sr_return_amt,
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY sr_returned_date_sk DESC) as rn
    FROM 
        store_returns
    WHERE 
        sr_return_quantity > 0
),
CurrentYearSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales
    FROM 
        web_sales
    INNER JOIN 
        date_dim ON ws_sold_date_sk = d_date_sk
    WHERE 
        d_year = EXTRACT(YEAR FROM cast('2002-10-01' as date))
    GROUP BY 
        ws_item_sk
),
TotalInventory AS (
    SELECT 
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_quantity
    FROM 
        inventory
    GROUP BY 
        inv_item_sk
),
ItemDetails AS (
    SELECT 
        i_item_sk,
        i_item_desc,
        i_current_price,
        COALESCE(total_sales.total_sales, 0) AS total_sales,
        COALESCE(total_quantity.total_quantity, 0) AS total_quantity
    FROM 
        item
    LEFT JOIN 
        CurrentYearSales total_sales ON i_item_sk = total_sales.ws_item_sk
    LEFT JOIN 
        TotalInventory total_quantity ON i_item_sk = total_quantity.inv_item_sk
)
SELECT 
    ad.ca_city,
    COUNT(DISTINCT c.c_customer_id) AS customer_count,
    SUM(id.total_sales) AS total_sales,
    SUM(rr.sr_return_quantity) AS total_returns,
    AVG(id.i_current_price) AS avg_item_price
FROM 
    ItemDetails id
JOIN 
    store s ON id.i_item_sk = s.s_store_sk
JOIN 
    customer c ON s.s_store_sk = c.c_current_addr_sk
JOIN 
    customer_address ad ON c.c_current_addr_sk = ad.ca_address_sk
LEFT JOIN 
    RankedReturns rr ON id.i_item_sk = rr.sr_item_sk AND rr.rn = 1
WHERE 
    ad.ca_state = 'CA' 
    AND id.total_sales > 0
GROUP BY 
    ad.ca_city
HAVING 
    SUM(rr.sr_return_quantity) > 10
ORDER BY 
    customer_count DESC;