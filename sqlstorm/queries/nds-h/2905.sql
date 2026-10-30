
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        p.p_partkey,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
SupplierPerformance AS (
    SELECT 
        n.n_name,
        SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_extendedprice * (1 - l.l_discount) ELSE 0 END) AS returned_value,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value,
        s.s_nationkey
    FROM 
        lineitem l
    JOIN 
        supplier s ON l.l_suppkey = s.s_suppkey
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        n.n_name, s.s_nationkey
)
SELECT 
    p.p_name,
    COALESCE(r.s_name, 'No Supplier') AS supplier_name,
    cp.order_count,
    cp.total_spent,
    sp.total_value,
    sp.returned_value
FROM 
    part p
LEFT JOIN 
    RankedSuppliers r ON p.p_partkey = r.p_partkey AND r.rank = 1
LEFT JOIN 
    CustomerOrders cp ON cp.c_custkey = (SELECT MIN(c.c_custkey) FROM customer c WHERE c.c_mktsegment = 'BUILDING')
LEFT JOIN 
    SupplierPerformance sp ON sp.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'FRANCE')
WHERE 
    p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2) 
    AND p.p_container IS NOT NULL
ORDER BY 
    p.p_name ASC;
