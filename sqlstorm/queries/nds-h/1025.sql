
WITH SupplierSummary AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey, s.s_name
),
OrderTotals AS (
    SELECT
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE
        o.o_orderstatus = 'O'
    GROUP BY
        o.o_orderkey, o.o_custkey
),
RegionNations AS (
    SELECT
        r.r_regionkey,
        r.r_name,
        COUNT(n.n_nationkey) AS nation_count
    FROM
        region r
    LEFT JOIN
        nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY
        r.r_regionkey, r.r_name
),
TopSuppliers AS (
    SELECT
        ss.s_suppkey,
        ss.s_name,
        ss.total_available,
        ss.avg_supplycost,
        ROW_NUMBER() OVER (ORDER BY ss.total_available DESC) AS rn
    FROM
        SupplierSummary ss
    WHERE
        ss.total_available > 1000
)
SELECT
    rn.r_name,
    ts.s_name,
    ts.total_available,
    ot.total_order_value,
    CASE 
        WHEN ot.total_order_value IS NULL THEN 'No Orders'
        ELSE 'Has Orders'
    END AS order_status
FROM
    RegionNations rn
FULL OUTER JOIN
    TopSuppliers ts ON rn.nation_count BETWEEN 5 AND 10
LEFT JOIN
    OrderTotals ot ON ts.s_suppkey = ot.o_custkey
WHERE
    (ts.total_available IS NOT NULL AND ts.total_available > 500) 
    OR 
    (ot.total_order_value IS NULL AND rn.nation_count < 15)
ORDER BY
    rn.r_name, ts.total_available DESC;
