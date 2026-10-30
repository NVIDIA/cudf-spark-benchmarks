
WITH SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        ws_ship_mode_sk,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022)
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        ws_item_sk, ws_ship_mode_sk
),
TopSales AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_sales,
        sm.sm_ship_mode_id,
        sm.sm_type,
        (sd.total_sales / NULLIF(sd.total_quantity, 0)) AS average_price
    FROM 
        SalesData sd
    JOIN 
        ship_mode sm ON sd.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE 
        sd.rank = 1
),
AddressInfo AS (
    SELECT 
        c.c_customer_sk,
        ca.ca_street_name,
        ca.ca_city,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY ca.ca_zip) AS addr_rank
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesStats AS (
    SELECT 
        t.ws_item_sk,
        t.total_sales,
        ai.ca_city,
        ai.ca_street_name,
        COUNT(DISTINCT ai.c_customer_sk) AS unique_customers,
        COUNT(DISTINCT CASE WHEN ai.addr_rank = 1 THEN ai.c_customer_sk END) AS one_address_customers
    FROM 
        TopSales t
    LEFT JOIN 
        AddressInfo ai ON t.ws_item_sk = ai.c_customer_sk
    LEFT JOIN 
        (SELECT 
            ir.inv_item_sk,
            SUM(ir.inv_quantity_on_hand) AS total_stock 
            FROM 
            inventory ir 
            GROUP BY ir.inv_item_sk) AS stock ON t.ws_item_sk = stock.inv_item_sk
    GROUP BY 
        t.ws_item_sk, t.total_sales, ai.ca_city, ai.ca_street_name
)
SELECT 
    st.ws_item_sk,
    st.total_sales,
    st.ca_city,
    st.ca_street_name,
    st.unique_customers,
    st.one_address_customers,
    CASE 
        WHEN st.unique_customers > 0 THEN (st.one_address_customers / NULLIF(st.unique_customers, 0))
        ELSE NULL 
    END AS one_address_ratio,
    CASE 
        WHEN st.total_sales > 1000 THEN 'High Sales'
        WHEN st.total_sales BETWEEN 500 AND 1000 THEN 'Medium Sales'
        ELSE 'Low Sales'
    END AS sales_category,
    COALESCE(SUBSTRING(UPPER(st.ca_street_name), LENGTH(st.ca_street_name) - 3, 4), 'Unknown') AS masked_street_name 
FROM 
    SalesStats st
WHERE 
    st.unique_customers > 10
ORDER BY 
    st.total_sales DESC
LIMIT 10;
