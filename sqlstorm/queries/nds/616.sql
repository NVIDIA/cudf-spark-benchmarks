
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM web_sales
    GROUP BY ws_bill_customer_sk, ws_item_sk
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
HighValueCustomers AS (
    SELECT 
        cd.c_customer_sk,
        cd.c_first_name,
        cd.c_last_name,
        cd.ca_city,
        cd.ca_state,
        SUM(rs.total_sales) AS total_sales
    FROM CustomerDetails cd
    JOIN RankedSales rs ON cd.c_customer_sk = rs.ws_bill_customer_sk
    WHERE rs.sales_rank <= 5
    GROUP BY cd.c_customer_sk, cd.c_first_name, cd.c_last_name, cd.ca_city, cd.ca_state
),
OrderSummary AS (
    SELECT 
        w.w_warehouse_name,
        COALESCE(SUM(ws.ws_quantity), 0) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit
    FROM warehouse w
    LEFT JOIN web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY w.w_warehouse_name
)
SELECT 
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.ca_city,
    hvc.ca_state,
    hvc.total_sales,
    os.total_quantity,
    os.total_profit
FROM HighValueCustomers hvc
FULL OUTER JOIN OrderSummary os ON hvc.total_sales > 5000
ORDER BY hvc.total_sales DESC, os.total_profit DESC
LIMIT 100;
