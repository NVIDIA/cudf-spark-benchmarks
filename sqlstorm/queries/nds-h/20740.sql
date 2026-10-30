
WITH RankedOrders AS (
    SELECT
        o.o_orderkey,
        o.o_orderstatus,
        o.o_orderdate,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM
        orders o
    WHERE
        o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2 WHERE o2.o_orderdate < DATE '1998-10-01')
),
SupplierDetails AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE
        s.s_acctbal IS NOT NULL
    GROUP BY
        s.s_suppkey, s.s_name
),
OrderLineDetails AS (
    SELECT
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
        COUNT(*) AS line_count,
        MAX(l.l_shipdate) AS last_ship_date
    FROM
        lineitem l
    WHERE
        l.l_returnflag = 'N'
    GROUP BY
        l.l_orderkey
),
CompositeResults AS (
    SELECT
        o.o_orderkey,
        o.o_orderstatus,
        od.net_revenue,
        od.line_count,
        sd.total_supply_cost,
        CASE 
            WHEN od.line_count IS NULL THEN 'NO LINES'
            WHEN od.line_count = 0 THEN 'NO REVENUE'
            ELSE 'ACTIVE'
        END AS line_status
    FROM 
        RankedOrders o
    LEFT JOIN 
        OrderLineDetails od ON o.o_orderkey = od.l_orderkey
    LEFT JOIN 
        SupplierDetails sd ON od.line_count > (SELECT COUNT(*) FROM supplier WHERE s_acctbal < 0)
)
SELECT
    cr.o_orderkey,
    cr.o_orderstatus,
    cr.net_revenue,
    cr.line_count,
    cr.total_supply_cost,
    cr.line_status
FROM
    CompositeResults cr
WHERE
    cr.line_status = 'ACTIVE'
    AND cr.total_supply_cost IS NOT NULL 
    AND (cr.net_revenue / NULLIF(cr.line_count, 0) > 1000 OR cr.total_supply_cost IS NULL)
ORDER BY
    cr.net_revenue DESC,
    cr.o_orderkey
LIMIT 100 OFFSET 50;
