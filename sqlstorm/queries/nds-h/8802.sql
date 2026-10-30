WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost,
        COUNT(DISTINCT p.p_partkey) AS TotalPartsSupplied
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_suppkey, s.s_name
),
OrderStats AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue,
        COUNT(DISTINCT l.l_linenumber) AS TotalLineItems
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
    GROUP BY o.o_orderkey, o.o_orderdate
),
RegionStats AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS TotalNations,
        SUM(s.s_acctbal) AS TotalSupplierBalance
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY r.r_regionkey, r.r_name
)
SELECT 
    ss.s_name,
    rs.r_name,
    ss.TotalSupplyCost,
    os.TotalRevenue,
    os.TotalLineItems,
    rs.TotalNations,
    rs.TotalSupplierBalance
FROM SupplierStats ss
JOIN OrderStats os ON ss.s_suppkey = os.o_orderkey
JOIN RegionStats rs ON ss.s_name = rs.r_name
ORDER BY ss.TotalSupplyCost DESC, os.TotalRevenue DESC;