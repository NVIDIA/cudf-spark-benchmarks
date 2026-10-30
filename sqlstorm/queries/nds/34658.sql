WITH  SalesCTE AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (
            SELECT MIN(d_date_sk) 
            FROM date_dim 
            WHERE d_date BETWEEN '1999-01-01' AND '1999-12-31'
        ) AND (
            SELECT MAX(d_date_sk) 
            FROM date_dim 
            WHERE d_date BETWEEN '1999-01-01' AND '1999-12-31'
        )
    GROUP BY 
        ws_item_sk
),
TopItems AS (
    SELECT 
        si.i_item_id,
        si.i_item_desc,
        s.total_sales
    FROM 
        SalesCTE s
    JOIN 
        item si ON s.ws_item_sk = si.i_item_sk
    WHERE 
        s.rn <= 5  
),
AddressCounts AS (
    SELECT 
        ca_city,
        COUNT(DISTINCT c_customer_id) AS customer_count
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY 
        ca_city
),
HighestAddresses AS (
    SELECT 
        ac.ca_city,
        ac.customer_count,
        DENSE_RANK() OVER (ORDER BY ac.customer_count DESC) AS rank
    FROM 
        AddressCounts ac
)
SELECT 
    t.i_item_id,
    t.i_item_desc,
    t.total_sales,
    ha.ca_city,
    ha.customer_count
FROM 
    TopItems t
LEFT JOIN 
    HighestAddresses ha ON ha.rank = 1  
WHERE 
    t.total_sales IS NOT NULL
ORDER BY 
    t.total_sales DESC;