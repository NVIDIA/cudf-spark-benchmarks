WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY s.s_acctbal DESC) as rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
TopCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 1000
),
PopularParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        SUM(l.l_quantity) AS total_quantity
    FROM 
        part p 
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
    ORDER BY 
        total_quantity DESC
    LIMIT 5
)
SELECT 
    r.r_name AS region,
    ns.n_name AS nation,
    s.s_name AS supplier_name,
    pc.p_name AS popular_part,
    tc.c_name AS top_customer,
    rs.s_acctbal AS supplier_balance,
    tc.total_spent AS customer_spending
FROM 
    RankedSuppliers rs
JOIN 
    supplier s ON rs.s_suppkey = s.s_suppkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    nation ns ON s.s_nationkey = ns.n_nationkey
JOIN 
    region r ON ns.n_regionkey = r.r_regionkey
JOIN 
    PopularParts pc ON p.p_partkey = pc.p_partkey
JOIN 
    TopCustomers tc ON s.s_suppkey IN (
        SELECT s_nationkey 
        FROM supplier 
        WHERE s_acctbal > 0
    )
WHERE 
    rs.rn = 1
ORDER BY 
    tc.total_spent DESC, 
    supplier_balance DESC;
