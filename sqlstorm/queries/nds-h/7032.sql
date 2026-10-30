
WITH  customer_orders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        c.c_acctbal, 
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_acctbal
),
top_customers AS (
    SELECT 
        c.c_custkey AS custkey, 
        c.c_name AS name, 
        c.total_spent,
        ROW_NUMBER() OVER (ORDER BY c.total_spent DESC) AS rank
    FROM 
        customer_orders c
)
SELECT 
    r.r_name AS region, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT CASE WHEN tc.rank <= 10 THEN tc.custkey END) AS top_customer_count
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey AND s.s_suppkey = ps.ps_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    top_customers tc ON c.c_custkey = tc.custkey
WHERE 
    o.o_orderdate >= DATE '1996-01-01' AND 
    o.o_orderdate < DATE '1997-01-01'
GROUP BY 
    r.r_name
ORDER BY 
    total_revenue DESC;
