
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS number_of_orders
    FROM 
        customer AS c
    JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        c.c_customer_id
), 
AddressDemographics AS (
    SELECT 
        ca.ca_country,
        COUNT(DISTINCT cd.cd_demo_sk) AS customers_count,
        SUM(cd.cd_purchase_estimate) AS total_purchase_estimate
    FROM 
        customer_demographics AS cd
    JOIN 
        customer AS c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    JOIN 
        customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        ca.ca_country
), 
SalesSummary AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        AVG(ss.ss_net_profit) AS avg_net_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions
    FROM 
        store_sales AS ss
    JOIN 
        warehouse AS w ON ss.ss_store_sk = w.w_warehouse_sk
    WHERE 
        ss.ss_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        w.w_warehouse_id
)
SELECT 
    cs.c_customer_id,
    cs.total_sales,
    cs.number_of_orders,
    ad.customers_count,
    ad.total_purchase_estimate,
    ss.total_store_sales,
    ss.avg_net_profit,
    ss.total_transactions
FROM 
    CustomerSales AS cs
JOIN 
    AddressDemographics AS ad ON ad.customers_count > 100 
JOIN 
    SalesSummary AS ss ON ss.total_store_sales > 10000
ORDER BY 
    cs.total_sales DESC, ad.customers_count DESC;
