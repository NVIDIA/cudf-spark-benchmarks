WITH TotalRevenue AS (
    SELECT 
        c.c_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        c.c_custkey
),
TopCustomers AS (
    SELECT 
        c.c_name,
        c.c_acctbal,
        tr.revenue
    FROM 
        customer c
    JOIN 
        TotalRevenue tr ON c.c_custkey = tr.c_custkey
    WHERE 
        tr.revenue > (SELECT AVG(revenue) FROM TotalRevenue)
    ORDER BY 
        tr.revenue DESC
    LIMIT 10
)
SELECT 
    tc.c_name,
    tc.c_acctbal,
    tc.revenue,
    r.r_name
FROM 
    TopCustomers tc
JOIN 
    supplier s ON s.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    region r ON p.p_container = r.r_name
WHERE 
    p.p_retailprice > 50.00
ORDER BY 
    tc.revenue DESC, tc.c_name ASC;