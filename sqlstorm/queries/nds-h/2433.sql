WITH RankedOrders AS (
    SELECT o.o_orderkey, 
           o.o_orderdate, 
           o.o_totalprice,
           RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) AS price_rank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderstatus = 'O'
), SupplierDetails AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
           COUNT(DISTINCT ps.ps_partkey) AS unique_parts
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
), LineItemSummary AS (
    SELECT l.l_orderkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           MAX(l.l_shipdate) AS latest_ship_date,
           COUNT(DISTINCT l.l_partkey) AS part_count
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT ro.o_orderkey, 
       ro.o_orderdate, 
       ro.o_totalprice,
       sd.s_name,
       ls.total_revenue,
       ls.latest_ship_date,
       sd.total_supply_cost,
       sd.unique_parts
FROM RankedOrders ro
LEFT JOIN LineItemSummary ls ON ro.o_orderkey = ls.l_orderkey
LEFT JOIN SupplierDetails sd ON sd.total_supply_cost > (SELECT AVG(total_supply_cost) FROM SupplierDetails)
WHERE ro.price_rank <= 5
ORDER BY ro.o_orderdate DESC, ls.total_revenue DESC;
