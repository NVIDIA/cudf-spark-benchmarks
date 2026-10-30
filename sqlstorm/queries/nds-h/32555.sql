
WITH  RankedCustomers AS (
    SELECT c_custkey, c_name, c_acctbal, c_mktsegment, 
           ROW_NUMBER() OVER (PARTITION BY c_mktsegment ORDER BY c_acctbal DESC) AS rank
    FROM customer
),
SupplierParts AS (
    SELECT ps.ps_partkey, s.s_suppkey, s.s_name, ps.ps_availqty, ps.ps_supplycost,
           ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost ASC) AS supplier_rank
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE ps.ps_availqty > 0
),
OrderLineItems AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate >= DATE '1998-10-01' - INTERVAL '30 days'
    GROUP BY o.o_orderkey
)
SELECT r.c_name, r.c_acctbal, r.c_mktsegment, 
       COALESCE(sp.supply_info, 'No supply available') AS supply_info,
       ol.total_price
FROM RankedCustomers r
LEFT JOIN (
    SELECT s.s_name AS supply_info, ps.ps_partkey
    FROM SupplierParts ps
    JOIN supplier s ON ps.s_suppkey = s.s_suppkey
    WHERE ps.supplier_rank = 1
) sp ON sp.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_brand = 'Brand#12')
LEFT JOIN OrderLineItems ol ON ol.o_orderkey = r.c_custkey
WHERE r.rank <= 10
ORDER BY r.c_acctbal DESC, ol.total_price DESC;
