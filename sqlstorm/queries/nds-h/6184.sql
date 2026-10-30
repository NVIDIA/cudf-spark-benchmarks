WITH supplier_stats AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
region_summary AS (
    SELECT r.r_regionkey, r.r_name, COUNT(DISTINCT n.n_nationkey) AS nation_count
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY r.r_regionkey, r.r_name
),
top_suppliers AS (
    SELECT s.s_suppkey, s.s_name, ROW_NUMBER() OVER (ORDER BY total_supply_cost DESC) AS rank
    FROM supplier_stats s
),
order_summary AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_custkey
)
SELECT 
    r.r_name AS region,
    ts.s_name AS top_supplier,
    os.total_order_value,
    os.o_orderkey
FROM 
    region_summary r
JOIN 
    nation n ON n.n_regionkey = r.r_regionkey
JOIN 
    supplier s ON s.s_nationkey = n.n_nationkey
JOIN 
    top_suppliers ts ON s.s_suppkey = ts.s_suppkey
JOIN 
    order_summary os ON os.o_custkey = s.s_suppkey
WHERE 
    ts.rank <= 5
ORDER BY 
    r.r_name, os.total_order_value DESC;
