WITH supplier_stats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        AVG(s.s_acctbal) AS avg_acct_balance
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
customer_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
nation_region AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_regionkey,
        r.r_name
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
),
final_stats AS (
    SELECT 
        ns.n_name AS nation_name,
        rs.r_name AS region_name,
        COUNT(DISTINCT cs.c_custkey) AS total_customers,
        SUM(cs.total_orders) AS total_orders_placed,
        SUM(cs.total_spent) AS total_revenue,
        COUNT(DISTINCT ss.s_suppkey) AS total_suppliers,
        SUM(ss.total_supply_cost) AS total_supplier_cost,
        AVG(ss.avg_acct_balance) AS avg_supplier_balance
    FROM customer_orders cs
    JOIN supplier_stats ss ON cs.c_custkey = ss.s_suppkey
    JOIN nation_region ns ON ss.s_suppkey = ns.n_nationkey
    JOIN region rs ON ns.r_regionkey = rs.r_regionkey
    GROUP BY ns.n_name, rs.r_name
)
SELECT 
    nation_name,
    region_name,
    total_customers,
    total_orders_placed,
    total_revenue,
    total_suppliers,
    total_supplier_cost,
    avg_supplier_balance
FROM final_stats
ORDER BY total_revenue DESC, total_orders_placed DESC;
