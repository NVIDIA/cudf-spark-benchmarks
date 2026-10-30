
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON p.p_partkey = ps.ps_partkey
    WHERE 
        s.s_acctbal IS NOT NULL AND s.s_acctbal > 1000.00
),
OrderSummary AS (
    SELECT 
        o.o_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' 
        AND o.o_orderstatus = 'O'
    GROUP BY 
        o.o_custkey
),
CustomerDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        r.r_name AS region_name,
        cs.total_spent,
        cs.order_count
    FROM 
        customer c
    JOIN 
        region r ON c.c_nationkey = r.r_regionkey
    LEFT JOIN 
        OrderSummary cs ON c.c_custkey = cs.o_custkey
)
SELECT 
    cd.c_custkey, 
    cd.c_name, 
    COALESCE(cd.total_spent, 0) AS total_spent,
    COALESCE(cd.order_count, 0) AS order_count,
    ARRAY_AGG(DISTINCT s.s_name) AS supplier_names,
    COUNT(DISTINCT ps.ps_partkey) AS part_count
FROM 
    CustomerDetails cd
LEFT JOIN 
    RankedSuppliers s ON cd.c_custkey IN (SELECT DISTINCT o.o_custkey FROM orders o WHERE o.o_orderkey IN 
        (SELECT l.l_orderkey FROM lineitem l WHERE l.l_discount > 0.1 AND l.l_returnflag = 'N'))
LEFT JOIN 
    partsupp ps ON ps.ps_suppkey = s.s_suppkey
GROUP BY 
    cd.c_custkey, 
    cd.c_name, 
    cd.total_spent, 
    cd.order_count
HAVING 
    COUNT(DISTINCT ps.ps_partkey) > 5
ORDER BY 
    total_spent DESC 
LIMIT 10;
