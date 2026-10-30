WITH RankedOrders AS (
    SELECT o.o_orderkey,
           o.o_orderdate,
           o.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderstatus IN ('O', 'F') AND o.o_totalprice > (SELECT AVG(o_totalprice) FROM orders)
),
SupplierDetails AS (
    SELECT s.s_suppkey,
           s.s_name,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
           COUNT(DISTINCT ps.ps_partkey) AS total_parts
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT s.s_suppkey,
           s.s_name,
           sd.total_supply_cost,
           RANK() OVER (ORDER BY sd.total_supply_cost DESC) AS supplier_rank
    FROM SupplierDetails sd
    JOIN supplier s ON sd.s_suppkey = s.s_suppkey
    WHERE sd.total_parts > 5
)
SELECT o.o_orderkey,
       o.o_orderdate,
       o.o_totalprice,
       ts.s_name AS supplier_name,
       (SELECT COUNT(DISTINCT l.l_orderkey)
        FROM lineitem l
        WHERE l.l_orderkey = o.o_orderkey) AS line_item_count,
       CASE 
           WHEN o.o_totalprice > 50000 THEN 'High Value'
           ELSE 'Regular Value'
       END AS order_value_category
FROM RankedOrders o
LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN TopSuppliers ts ON l.l_suppkey = ts.s_suppkey
WHERE o.order_rank <= 10
  AND (ts.s_name IS NULL OR ts.supplier_rank <= 3)
ORDER BY o.o_orderdate DESC, o.o_totalprice DESC;
