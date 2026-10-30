
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate >= DATE '1997-01-01'
),
SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        COUNT(DISTINCT p.p_partkey) AS part_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_availqty) > 1000
),
OrderLines AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(*) AS line_count
    FROM lineitem l
    WHERE l.l_shipdate < DATE '1998-10-01'
    GROUP BY l.l_orderkey
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 50000
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.o_totalprice,
    COALESCE(o.total_revenue, 0) AS total_revenue,
    ss.s_name,
    COALESCE(ss.total_avail_qty, 0) AS total_avail_qty,
    COALESCE(ss.avg_supply_cost, 0) AS avg_supply_cost,
    COALESCE(ss.part_count, 0) AS unique_parts
FROM RankedOrders r
LEFT JOIN OrderLines o ON r.o_orderkey = o.l_orderkey
LEFT JOIN SupplierSummary ss ON ss.total_avail_qty > 1500
WHERE r.order_rank <= 10 AND (r.o_totalprice > 1000 OR COALESCE(o.total_revenue, 0) > 3000)
ORDER BY r.o_orderdate DESC;
