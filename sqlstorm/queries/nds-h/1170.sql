
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY ps_partkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        ps.ps_availqty > 0
), 
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus <> 'F'
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 5000
), 
ProductMetrics AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_orderkey) AS order_count
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
)
SELECT 
    r.s_name,
    pm.p_name,
    pm.total_revenue,
    hvc.total_spent,
    COALESCE(hvc.total_spent, 0) AS total_spent_by_high_value_customers,
    (SELECT AVG(ps.ps_supplycost) FROM partsupp ps WHERE ps.ps_partkey = pm.p_partkey) AS avg_supply_cost
FROM 
    RankedSuppliers r
JOIN 
    ProductMetrics pm ON r.s_suppkey = pm.p_partkey
LEFT JOIN 
    HighValueCustomers hvc ON r.s_suppkey = hvc.c_custkey
WHERE 
    r.rank = 1
ORDER BY 
    pm.total_revenue DESC, r.s_name;
