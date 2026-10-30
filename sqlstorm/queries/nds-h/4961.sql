WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) as supplier_rank,
        p.p_partkey
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
        c.c_name,
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        MAX(co.total_spent) AS max_spent
    FROM 
        CustomerOrders co
    JOIN 
        customer c ON co.c_custkey = c.c_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        MAX(co.total_spent) > 10000
)
SELECT 
    rs.s_name,
    rs.s_acctbal,
    p.p_name,
    p.p_brand,
    CASE 
        WHEN rs.s_acctbal IS NULL THEN 'No Account Balance'
        ELSE 'Account Balance Exists'
    END AS balance_status,
    tc.max_spent
FROM 
    RankedSuppliers rs
LEFT JOIN 
    part p ON rs.p_partkey = p.p_partkey
LEFT JOIN 
    TopCustomers tc ON rs.s_suppkey = tc.c_custkey
WHERE 
    rs.supplier_rank = 1
AND 
    (p.p_mfgr LIKE '%MFG%' OR p.p_retailprice > 50)
ORDER BY 
    p.p_retailprice DESC, rs.s_acctbal DESC;
