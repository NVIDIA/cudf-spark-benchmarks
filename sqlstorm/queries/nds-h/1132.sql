WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) as rnk
    FROM 
        supplier s
), 

HighValueParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM 
        part p 
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand
    HAVING 
        AVG(ps.ps_supplycost) > 100.00
), 

CustomerOrders AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
    HAVING 
        SUM(o.o_totalprice) > 5000.00
)

SELECT 
    n.n_name AS nation_name,
    COUNT(DISTINCT cu.c_custkey) AS total_customers,
    COALESCE(SUM(tv.total_spent), 0) AS total_spent_by_high_value_customers,
    COALESCE(AVG(tv.total_spent), 0) AS avg_spent_per_high_value_customer,
    COUNT(DISTINCT rp.s_suppkey) AS suppliers_with_high_acctbal
FROM 
    nation n
LEFT JOIN 
    customer cu ON cu.c_nationkey = n.n_nationkey
LEFT JOIN 
    CustomerOrders tv ON tv.c_custkey = cu.c_custkey
LEFT JOIN 
    RankedSuppliers rp ON rp.rnk = 1 AND rp.s_nationkey = n.n_nationkey
GROUP BY 
    n.n_name
ORDER BY 
    nation_name DESC;