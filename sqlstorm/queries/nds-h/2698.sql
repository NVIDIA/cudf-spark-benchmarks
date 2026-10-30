WITH RankedOrders AS (
    SELECT o.o_orderkey,
           o.o_orderdate,
           o.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) as order_rank
    FROM orders o
    WHERE o.o_orderdate >= DATE '1997-01-01'
      AND o.o_orderdate < DATE '1998-01-01'
),
SupplierStats AS (
    SELECT s.s_suppkey,
           s.s_name,
           COUNT(DISTINCT ps.ps_partkey) AS part_count,
           SUM(ps.ps_availqty) AS total_available
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
FilteredLineItems AS (
    SELECT l.l_orderkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
           COUNT(*) AS item_count
    FROM lineitem l
    WHERE l.l_shipdate BETWEEN DATE '1997-03-01' AND DATE '1997-12-31'
    GROUP BY l.l_orderkey
)
SELECT r.o_orderkey,
       r.o_orderdate,
       r.o_totalprice,
       COALESCE(s.part_count, 0) AS supplier_part_count,
       COALESCE(s.total_available, 0) AS supplier_total_available,
       fl.net_revenue,
       fl.item_count,
       (fl.net_revenue / NULLIF(r.o_totalprice, 0)) AS revenue_ratio
FROM RankedOrders r
LEFT JOIN SupplierStats s ON r.o_orderkey = s.s_suppkey
LEFT JOIN FilteredLineItems fl ON r.o_orderkey = fl.l_orderkey
WHERE r.order_rank <= 10
  AND (fl.net_revenue IS NOT NULL OR s.part_count > 0)
ORDER BY revenue_ratio DESC NULLS LAST;