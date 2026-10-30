WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS SupplierRank
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
        COUNT(o.o_orderkey) AS order_count, 
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
TopCustomers AS (
    SELECT 
        *, 
        RANK() OVER (ORDER BY total_spent DESC) AS customer_rank
    FROM 
        CustomerOrders
    WHERE 
        order_count > 0
)
SELECT 
    nc.n_name AS nation_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COALESCE(SUM(rsu.s_acctbal), 0) AS total_supplier_balance,
    tc.c_name AS top_customer_name,
    tc.total_spent AS top_customer_spent
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
LEFT JOIN 
    (SELECT p.p_partkey, ps.ps_supplycost FROM part p JOIN partsupp ps ON p.p_partkey = ps.ps_partkey WHERE ps.ps_availqty > 0) AS ps ON l.l_partkey = ps.p_partkey
JOIN 
    nation nc ON s.s_nationkey = nc.n_nationkey
LEFT JOIN 
    RankedSuppliers rsu ON rsu.s_suppkey = s.s_suppkey AND rsu.SupplierRank = 1
JOIN 
    TopCustomers tc ON c.c_custkey = tc.c_custkey
WHERE 
    l.l_shipdate BETWEEN '1996-01-01' AND '1996-12-31'
    AND l.l_returnflag = 'N'
GROUP BY 
    nc.n_name, tc.c_name, tc.total_spent
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 100000
ORDER BY 
    total_revenue DESC, top_customer_spent DESC;