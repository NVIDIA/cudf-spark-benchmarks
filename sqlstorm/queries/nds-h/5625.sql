WITH SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value,
        COUNT(DISTINCT p.p_partkey) AS part_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_suppkey, s.s_name
), 
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey, c.c_name
) 
SELECT 
    rs.r_name,
    SUM(ss.total_value) AS total_supplier_value,
    SUM(os.total_spent) AS total_customer_spent,
    COUNT(DISTINCT ss.s_suppkey) AS supplier_count,
    COUNT(DISTINCT os.c_custkey) AS customer_count 
FROM region rs
JOIN nation n ON rs.r_regionkey = n.n_regionkey
JOIN supplier s ON n.n_nationkey = s.s_nationkey
JOIN SupplierSummary ss ON s.s_suppkey = ss.s_suppkey
JOIN CustomerOrderSummary os ON ss.total_value > 10000
GROUP BY rs.r_name
ORDER BY total_supplier_value DESC, total_customer_spent DESC;
