
WITH RankedOrders AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM
        orders o
    WHERE
        o.o_orderdate >= DATE '1996-01-01'
        AND o.o_orderdate <= DATE '1997-12-31'
),
SupplierStats AS (
    SELECT
        s.s_nationkey,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM
        supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_nationkey
),
OrderDetails AS (
    SELECT
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        COUNT(*) AS item_count
    FROM
        lineitem l
    GROUP BY
        l.l_orderkey
),
UnionedResults AS (
    SELECT
        r.r_name,
        ss.supplier_count,
        ss.total_avail_qty,
        ss.avg_supply_cost,
        COALESCE(od.revenue, 0) AS total_revenue
    FROM
        region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN SupplierStats ss ON n.n_nationkey = ss.s_nationkey
    LEFT JOIN OrderDetails od ON ss.supplier_count = (SELECT MAX(supplier_count) FROM SupplierStats)
)
SELECT
    ur.r_name,
    ur.supplier_count,
    ur.total_avail_qty,
    ur.avg_supply_cost,
    ur.total_revenue,
    CASE 
        WHEN ur.total_revenue IS NULL THEN 'No Revenue'
        WHEN ur.total_revenue > 100000 THEN 'High Revenue'
        ELSE 'Low Revenue' 
    END AS revenue_category
FROM
    UnionedResults ur
WHERE
    ur.avg_supply_cost IS NOT NULL
    OR ur.total_avail_qty = (SELECT MAX(total_avail_qty) FROM SupplierStats)
ORDER BY
    ur.total_revenue DESC,
    ur.supplier_count DESC;
