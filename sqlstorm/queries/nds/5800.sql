
WITH RankedSales AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM
        web_sales
    GROUP BY
        ws_bill_customer_sk
),
TopCustomers AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        r.total_sales,
        r.order_count
    FROM
        RankedSales r
    JOIN
        customer c ON r.ws_bill_customer_sk = c.c_customer_sk
    WHERE
        r.sales_rank <= 10
),
SalesByCategory AS (
    SELECT
        i.i_category,
        SUM(ws_sales_price) AS category_sales
    FROM
        web_sales ws
    JOIN
        item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY
        i.i_category
),
SalesByState AS (
    SELECT
        ca_state,
        SUM(ws_sales_price) AS state_sales
    FROM
        web_sales ws
    JOIN
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY
        ca_state
)
SELECT
    tc.c_customer_id,
    tc.c_first_name,
    tc.c_last_name,
    sbc.i_category,
    sbc.category_sales,
    sbs.ca_state,
    sbs.state_sales,
    tc.total_sales,
    tc.order_count
FROM
    TopCustomers tc
JOIN
    SalesByCategory sbc ON tc.total_sales > sbc.category_sales
JOIN
    SalesByState sbs ON tc.total_sales > sbs.state_sales
ORDER BY
    tc.total_sales DESC;
