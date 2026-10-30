WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY ps_partkey ORDER BY s_acctbal DESC) AS rnk
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
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
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal
    FROM 
        customer c
    WHERE 
        c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2)
),
PartRevenue AS (
    SELECT 
        p.p_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey
)
SELECT 
    r.r_name,
    pv.total_revenue,
    COALESCE(c.order_count, 0) AS total_orders,
    COALESCE(c.total_spent, 0) AS total_spent,
    s.s_name
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    (SELECT 
         p.p_partkey,
         SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
     FROM 
         lineitem l
     JOIN 
         partsupp ps ON l.l_partkey = ps.ps_partkey
     JOIN 
         part p ON ps.ps_partkey = p.p_partkey
     GROUP BY 
         p.p_partkey) pv ON s.s_suppkey = pv.p_partkey
LEFT JOIN 
    CustomerOrders c ON s.s_suppkey = c.c_custkey
WHERE 
    r.r_name LIKE 'N%' 
    AND (s.s_acctbal IS NOT NULL AND s.s_acctbal > 1000)
ORDER BY 
    pv.total_revenue DESC, c.total_spent DESC;
