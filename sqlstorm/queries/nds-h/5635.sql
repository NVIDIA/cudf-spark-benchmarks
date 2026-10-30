WITH RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_name, c.c_mktsegment,
           RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
),
TopCustomers AS (
    SELECT r.r_name AS region, n.n_name AS nation, o.order_rank, o.o_orderkey, o.o_totalprice, o.o_orderdate, o.c_name
    FROM RankedOrders o
    JOIN customer c ON o.o_orderkey = c.c_custkey
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE o.order_rank <= 5
),
PartSupplierInfo AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty, ps.ps_supplycost,
           p.p_name, p.p_brand, p.p_type
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
)
SELECT tc.region, tc.nation, tc.c_name AS customer_name, tc.o_orderkey, tc.o_totalprice,
       COUNT(DISTINCT psi.ps_suppkey) AS unique_suppliers,
       SUM(psi.ps_supplycost) AS total_supplycost,
       AVG(psi.ps_availqty) AS avg_avail_qty
FROM TopCustomers tc
LEFT JOIN PartSupplierInfo psi ON tc.o_orderkey = psi.ps_partkey
GROUP BY tc.region, tc.nation, tc.c_name, tc.o_orderkey, tc.o_totalprice
ORDER BY tc.region, tc.nation, tc.o_totalprice DESC;