WITH SupplierParts AS (
    SELECT s.s_suppkey, s.s_name, p.p_partkey, p.p_name, ps.ps_availqty, ps.ps_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON p.p_partkey = ps.ps_partkey
),
SalesData AS (
    SELECT o.o_orderkey, c.c_custkey, l.l_partkey, l.l_quantity, l.l_extendedprice, l.l_discount
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1997-10-01'
),
AggregatedSales AS (
    SELECT sd.l_partkey,
           SUM(sd.l_quantity) AS total_quantity,
           SUM(sd.l_extendedprice * (1 - sd.l_discount)) AS total_revenue
    FROM SalesData sd
    GROUP BY sd.l_partkey
),
RankedParts AS (
    SELECT sp.p_partkey, 
           sp.p_name, 
           ap.total_quantity, 
           ap.total_revenue,
           ROW_NUMBER() OVER (PARTITION BY sp.s_suppkey ORDER BY ap.total_revenue DESC) AS part_rank
    FROM SupplierParts sp
    JOIN AggregatedSales ap ON sp.p_partkey = ap.l_partkey
)
SELECT sp.s_name AS supplier_name, 
       rp.p_name AS part_name, 
       rp.total_quantity, 
       rp.total_revenue
FROM RankedParts rp
JOIN SupplierParts sp ON rp.p_partkey = sp.p_partkey
WHERE rp.part_rank <= 3
ORDER BY supplier_name, total_revenue DESC;