WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        o.o_shippriority,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate >= DATE '1997-01-01' 
      AND o.o_orderdate < DATE '1998-01-01'
),
FilteredLineItems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue
    FROM lineitem l
    WHERE l.l_returnflag = 'N'
      AND l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    GROUP BY l.l_orderkey
),
SuppliersWithDiscounts AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING AVG(ps.ps_supplycost) < 100.00
),
OrderSummary AS (
    SELECT 
        r.o_orderkey,
        COUNT(DISTINCT l.l_partkey) AS total_parts,
        SUM(COALESCE(fl.net_revenue, 0)) AS total_revenue
    FROM RankedOrders r
    LEFT JOIN FilteredLineItems fl ON r.o_orderkey = fl.l_orderkey
    LEFT JOIN lineitem l ON r.o_orderkey = l.l_orderkey
    WHERE r.order_rank <= 10
    GROUP BY r.o_orderkey
)
SELECT 
    os.o_orderkey,
    os.total_parts,
    os.total_revenue,
    s.s_name,
    s.avg_supplycost
FROM OrderSummary os
LEFT JOIN SuppliersWithDiscounts s ON os.total_parts = s.s_suppkey
WHERE os.total_revenue > (SELECT AVG(total_revenue) FROM OrderSummary)
ORDER BY os.total_revenue DESC, os.o_orderkey ASC;