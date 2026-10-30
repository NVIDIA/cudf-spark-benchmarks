
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        RANK() OVER (PARTITION BY o.o_orderdate ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '1997-01-01' 
      AND o.o_orderdate <= DATE '1997-12-31'
    GROUP BY o.o_orderkey, o.o_orderdate
),
TopOrders AS (
    SELECT * FROM RankedOrders WHERE order_rank <= 10
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, n.n_name
)
SELECT 
    so.o_orderkey,
    so.o_orderdate,
    td.total_supply_cost,
    CASE 
        WHEN td.total_supply_cost IS NULL THEN 'No Supplier'
        ELSE CONCAT(td.s_name, ' from ', td.nation_name)
    END AS supplier_info,
    (SELECT COUNT(*) FROM lineitem l2 WHERE l2.l_orderkey = so.o_orderkey) AS item_count,
    ROUND(AVG(td.total_supply_cost) OVER (), 2) AS avg_supplier_cost
FROM TopOrders so
LEFT JOIN SupplierDetails td ON so.o_orderkey = td.s_suppkey
ORDER BY so.o_orderdate;
