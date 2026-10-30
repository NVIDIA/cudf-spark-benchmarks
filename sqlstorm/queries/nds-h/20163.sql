
WITH RankedOrders AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank
    FROM
        orders o
    WHERE
        o.o_orderdate >= '1995-01-01' AND o.o_orderdate <= '1996-12-31'
),
SupplierDetails AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty * ps.ps_supplycost) AS total_supply_cost,
        ROW_NUMBER() OVER (ORDER BY SUM(ps.ps_availqty * ps.ps_supplycost) DESC) AS supply_rank
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey, s.s_name
),
LineItemSummary AS (
    SELECT
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(l.l_orderkey) AS total_items,
        AVG(l.l_quantity) AS avg_quantity
    FROM
        lineitem l
    WHERE
        l.l_shipdate > '1995-06-30' AND l.l_shipdate < '1996-01-01'
    GROUP BY
        l.l_orderkey
)
SELECT
    r.o_orderkey,
    r.o_orderdate,
    r.o_totalprice,
    COALESCE(s.s_name, 'No Supplier') AS supplier_name,
    l.total_revenue,
    l.total_items,
    l.avg_quantity,
    CASE 
        WHEN r.price_rank < 10 THEN 'Top Price'
        ELSE 'Other'
    END AS price_category
FROM
    RankedOrders r
LEFT JOIN
    SupplierDetails s ON r.o_orderkey = s.s_suppkey
LEFT JOIN
    LineItemSummary l ON r.o_orderkey = l.l_orderkey
WHERE
    r.o_orderstatus IN ('O', 'F')
    AND (l.total_revenue IS NOT NULL OR s.total_supply_cost IS NULL)
ORDER BY
    r.o_orderdate DESC, r.o_totalprice DESC;
