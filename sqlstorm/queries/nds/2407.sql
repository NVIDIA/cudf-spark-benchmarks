WITH RankedSales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS price_rank
    FROM
        web_sales ws
    WHERE
        ws.ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_date <= cast('2002-10-01' as date))
),
TotalReturns AS (
    SELECT
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_returned,
        COUNT(*) AS return_count
    FROM
        catalog_returns cr
    WHERE
        cr.cr_returned_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_date <= cast('2002-10-01' as date))
    GROUP BY
        cr.cr_item_sk
),
CustomerStats AS (
    SELECT
        c.c_customer_sk,
        cd.cd_gender,
        SUM(ws.ws_sales_price) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS orders_count,
        AVG(ws.ws_sales_price) AS average_spent_per_order
    FROM
        customer c
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY
        c.c_customer_sk, cd.cd_gender
),
FilteredItems AS (
    SELECT
        i.i_item_sk,
        i.i_item_desc,
        COALESCE(rs.price_rank, 0) AS highest_rank,
        COALESCE(tr.total_returned, 0) AS total_returns,
        ci.total_spent AS average_customer_spent
    FROM
        item i
    LEFT JOIN
        RankedSales rs ON i.i_item_sk = rs.ws_item_sk
    LEFT JOIN
        TotalReturns tr ON i.i_item_sk = tr.cr_item_sk
    LEFT JOIN
        (SELECT
             ws.ws_item_sk,
             AVG(c.total_spent) AS total_spent
         FROM
             web_sales ws
         JOIN
             CustomerStats c ON ws.ws_bill_customer_sk = c.c_customer_sk
         GROUP BY
             ws.ws_item_sk) ci ON i.i_item_sk = ci.ws_item_sk
)
SELECT
    fi.i_item_sk,
    fi.i_item_desc,
    fi.highest_rank,
    fi.total_returns,
    fi.average_customer_spent
FROM
    FilteredItems fi
WHERE
    fi.highest_rank > 0 OR fi.total_returns > 0
ORDER BY
    fi.average_customer_spent DESC, fi.total_returns DESC;