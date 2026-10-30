
WITH  SalesCTE AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        DENSE_RANK() OVER (ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
TopSales AS (
    SELECT 
        item.i_item_sk,
        item.i_item_id,
        COALESCE(sales.total_sales, 0) AS total_sales,
        COALESCE(sales.order_count, 0) AS order_count
    FROM 
        item 
    LEFT JOIN 
        SalesCTE sales ON item.i_item_sk = sales.ws_item_sk
    WHERE 
        item.i_current_price > 0
),
FilteredAddresses AS (
    SELECT 
        ca_address_sk,
        ca_city,
        ca_state,
        COUNT(c_customer_sk) AS customer_count
    FROM 
        customer_address 
    LEFT JOIN 
        customer ON customer.c_current_addr_sk = ca_address_sk
    GROUP BY 
        ca_address_sk, ca_city, ca_state
    HAVING 
        COUNT(c_customer_sk) > 10
),
AggregateSales AS (
    SELECT 
        storage.s_store_id,
        SUM(web.ws_ext_sales_price) AS total_web_sales,
        SUM(store.ss_ext_sales_price) AS total_store_sales
    FROM 
        store storage
    LEFT JOIN 
        store_sales store ON storage.s_store_sk = store.ss_store_sk
    LEFT JOIN 
        web_sales web ON storage.s_store_sk = web.ws_warehouse_sk
    GROUP BY 
        storage.s_store_id
)
SELECT 
    addr.ca_city,
    addr.ca_state,
    COALESCE(sales.total_sales, 0) AS item_sales,
    addr.customer_count,
    aggr.total_web_sales,
    aggr.total_store_sales,
    CASE 
        WHEN aggr.total_web_sales > aggr.total_store_sales THEN 'Web Dominant'
        ELSE 'Store Dominant'
    END AS sales_channel
FROM 
    FilteredAddresses addr
LEFT JOIN 
    TopSales sales ON sales.total_sales > 1000
LEFT JOIN 
    AggregateSales aggr ON aggr.s_store_id = CAST(addr.ca_address_sk AS VARCHAR(16))
WHERE 
    addr.customer_count < (SELECT COUNT(*) FROM customer) * 0.1
ORDER BY 
    item_sales DESC NULLS LAST
LIMIT 10;
