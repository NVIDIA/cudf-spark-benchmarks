WITH CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, o.o_orderkey, o.o_orderdate, o.o_totalprice
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
),
RankedLineItems AS (
    SELECT l.l_orderkey, l.l_partkey, l.l_suppkey, l.l_quantity, l.l_extendedprice,
           ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_extendedprice DESC) AS rn
    FROM lineitem l
    WHERE l.l_returnflag = 'N'
),
SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, AVG(s.s_acctbal) AS avg_acctbal
    FROM supplier s
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
TotalPartSupplies AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_avail_qty
    FROM partsupp ps
    GROUP BY ps.ps_partkey
)
SELECT co.c_name, co.o_orderkey, co.o_totalprice, rl.l_partkey, rl.l_quantity, 
       sd.s_name AS supplier_name, sd.avg_acctbal,
       tp.total_avail_qty,
       CASE 
           WHEN co.o_totalprice IS NULL THEN 'Price Not Available' 
           WHEN tp.total_avail_qty IS NULL THEN 'Quantity Not Available'
           ELSE 'Available'
       END AS availability_status
FROM CustomerOrders co
LEFT JOIN RankedLineItems rl ON co.o_orderkey = rl.l_orderkey AND rl.rn = 1
LEFT JOIN SupplierDetails sd ON rl.l_suppkey = sd.s_suppkey
LEFT JOIN TotalPartSupplies tp ON rl.l_partkey = tp.ps_partkey
WHERE co.c_name IS NOT NULL
ORDER BY co.o_orderdate DESC, co.o_totalprice DESC;