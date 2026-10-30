WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
),
NationalSummary AS (
    SELECT 
        n.n_regionkey, 
        n.n_nationkey, 
        n.n_name, 
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(CASE WHEN s.s_acctbal IS NULL THEN 0 ELSE s.s_acctbal END) AS total_acctbal,
        AVG(s.s_acctbal) AS avg_acctbal
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_regionkey, n.n_nationkey, n.n_name
),
TopCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey AND o.o_orderstatus = 'F'
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > (SELECT AVG(o_totalprice) FROM orders WHERE o_orderstatus = 'F')
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_avail
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
    HAVING 
        SUM(ps.ps_availqty) > 100
)
SELECT 
    ps.ps_partkey,
    p.p_name,
    p.p_mfgr,
    p.p_retailprice,
    ns.supplier_count,
    ns.total_acctbal,
    ns.avg_acctbal,
    tc.c_name,
    tc.total_spent
FROM 
    part p
LEFT JOIN 
    SupplierParts ps ON p.p_partkey = ps.ps_partkey
JOIN 
    NationalSummary ns ON ns.n_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_nationkey = (SELECT DISTINCT c.c_nationkey FROM customer c WHERE c.c_custkey IN (SELECT c.c_custkey FROM TopCustomers tc)))
LEFT JOIN 
    TopCustomers tc ON tc.total_spent = (SELECT MAX(total_spent) FROM TopCustomers)
WHERE 
    p.p_retailprice BETWEEN 10 AND 100
ORDER BY 
    ps.total_avail DESC NULLS LAST, 
    p.p_mfgr ASC
LIMIT 10;
