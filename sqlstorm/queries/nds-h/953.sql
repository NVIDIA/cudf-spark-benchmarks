
WITH CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(o.o_totalprice) DESC) AS rn
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
TopCustomers AS (
    SELECT 
        c.c_custkey AS custkey,
        c.c_name,
        c.total_spent,
        c.order_count,
        ROW_NUMBER() OVER (ORDER BY c.total_spent DESC) AS rank
    FROM 
        CustomerOrderSummary c
    WHERE 
        c.order_count > 5
)
SELECT 
    tc.c_name,
    COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_revenue,
    r.r_name AS region_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    ARRAY_AGG(DISTINCT p.p_name) FILTER (WHERE p.p_size >= 10) AS large_parts
FROM 
    TopCustomers tc
JOIN 
    orders o ON tc.custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    part p ON l.l_partkey = p.p_partkey
WHERE 
    l.l_shipdate >= DATE '1997-01-01' AND
    (l.l_returnflag = 'N' OR l.l_returnflag IS NULL)
GROUP BY 
    tc.c_name, r.r_name
HAVING 
    COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) > 10000
ORDER BY 
    total_revenue DESC,
    tc.c_name ASC;
