WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, n.n_name AS nation_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, n.n_name
),
OrderSummary AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_order_value, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O' AND o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY c.c_custkey
),
PartSales AS (
    SELECT l.l_partkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY l.l_partkey
)
SELECT 
    pd.s_name AS supplier_name,
    pd.nation_name,
    os.total_order_value,
    os.order_count,
    ps.total_sales
FROM SupplierDetails pd
LEFT JOIN OrderSummary os ON pd.s_suppkey = os.c_custkey  
LEFT JOIN PartSales ps ON pd.s_suppkey = ps.l_partkey    
WHERE pd.total_supply_cost > 10000.00
ORDER BY total_order_value DESC, ps.total_sales DESC;