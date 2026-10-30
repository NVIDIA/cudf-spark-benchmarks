WITH  SupplyChain AS (
    SELECT ps.ps_partkey, 
           ps.ps_suppkey, 
           ps.ps_availqty, 
           ps.ps_supplycost,
           ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost) AS rn
    FROM partsupp ps
    WHERE ps.ps_availqty > 0
),
RankedSuppliers AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           s.s_acctbal,
           SUM(sc.ps_supplycost * sc.ps_availqty) AS total_supply_value
    FROM Supplier s
    JOIN SupplyChain sc ON s.s_suppkey = sc.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal
    HAVING SUM(sc.ps_supplycost * sc.ps_availqty) > 10000
),
OrderSummary AS (
    SELECT o.o_orderkey, 
           o.o_orderdate,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
           COUNT(DISTINCT l.l_suppkey) AS supplier_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O' 
    GROUP BY o.o_orderkey, o.o_orderdate
),
BestOrders AS (
    SELECT os.o_orderkey,
           os.o_orderdate,
           os.total_price,
           os.supplier_count,
           RANK() OVER (ORDER BY os.total_price DESC) AS price_rank
    FROM OrderSummary os
),
FinalSummary AS (
    SELECT bo.o_orderkey,
           bo.o_orderdate,
           bo.total_price,
           bo.supplier_count,
           bs.s_name AS best_supplier
    FROM BestOrders bo
    LEFT JOIN RankedSuppliers bs ON bo.supplier_count = bs.total_supply_value
)
SELECT fs.o_orderkey, 
       fs.o_orderdate, 
       COALESCE(fs.total_price, 0) AS total_price,
       fs.supplier_count,
       CASE 
           WHEN fs.best_supplier IS NULL THEN 'No Supplier' 
           ELSE fs.best_supplier 
       END AS best_supplier
FROM FinalSummary fs
WHERE fs.supplier_count > 0
ORDER BY fs.o_orderdate DESC, fs.total_price DESC
LIMIT 10;
