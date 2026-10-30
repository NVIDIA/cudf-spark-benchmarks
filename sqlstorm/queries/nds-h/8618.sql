
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        n.n_name AS nation, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, n.n_name, n.n_nationkey
),
TopSuppliers AS (
    SELECT 
        ts.s_suppkey, 
        ts.s_name, 
        r.r_name AS region_name, 
        ts.total_supply_cost
    FROM RankedSuppliers ts
    JOIN nation n ON ts.nation = n.n_name
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE ts.rank <= 5
),
OrderStats AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        COUNT(DISTINCT l.l_partkey) AS part_count,
        COUNT(DISTINCT o.o_custkey) AS customer_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
)
SELECT 
    ts.region_name, 
    COUNT(DISTINCT os.o_orderkey) AS total_orders, 
    SUM(os.total_price) AS total_revenue, 
    AVG(os.part_count) AS avg_parts_per_order, 
    AVG(os.customer_count) AS avg_customers_per_order
FROM TopSuppliers ts
JOIN OrderStats os ON ts.s_suppkey = os.o_orderkey
GROUP BY ts.region_name
ORDER BY total_revenue DESC;
