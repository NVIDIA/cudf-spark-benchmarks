
WITH CustomerNames AS (
    SELECT CONCAT(c_first_name, ' ', c_last_name) AS full_name, c_current_addr_sk
    FROM customer
    WHERE c_preferred_cust_flag = 'Y'
),
AddressDetails AS (
    SELECT ca_address_sk, ca_city, ca_state, ca_zip
    FROM customer_address
    WHERE ca_state IN ('CA', 'NY', 'TX')
),
SalesData AS (
    SELECT 
        SUM(ws_ext_sales_price) AS total_sales, 
        COUNT(DISTINCT ws_order_number) AS total_orders,
        ws_bill_addr_sk
    FROM web_sales 
    WHERE ws_sold_date_sk IN (
        SELECT d_date_sk 
        FROM date_dim 
        WHERE d_year = 2023
    )
    GROUP BY ws_bill_addr_sk
),
RankedSales AS (
    SELECT 
        ad.ca_address_sk, 
        ad.ca_city, 
        ad.ca_state, 
        ad.ca_zip, 
        sd.total_sales, 
        sd.total_orders,
        ROW_NUMBER() OVER (PARTITION BY ad.ca_state ORDER BY sd.total_sales DESC) AS sales_rank
    FROM AddressDetails ad
    JOIN SalesData sd ON ad.ca_address_sk = sd.ws_bill_addr_sk
),
TopCustomers AS (
    SELECT 
        cn.full_name, 
        rs.ca_city, 
        rs.ca_state, 
        rs.ca_zip, 
        rs.total_sales
    FROM CustomerNames cn
    JOIN RankedSales rs ON cn.c_current_addr_sk = rs.ca_address_sk
    WHERE rs.sales_rank <= 5
)
SELECT 
    ca_state,
    COUNT(*) AS top_customers_count,
    SUM(total_sales) AS total_sales_sum
FROM TopCustomers
GROUP BY ca_state
ORDER BY ca_state;
